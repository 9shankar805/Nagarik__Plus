import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../services/contact_service.dart';

const _kBlue  = Color(0xFF3461FF);
const _kText  = Color(0xFF0D1B34);
const _kSub   = Color(0xFF8A96A8);
const _kBord  = Color(0xFFE4EAF4);
const _kBg    = Color(0xFFF0F4FF);
const _kWhite = Colors.white;

class FilePickerScreen extends StatefulWidget {
  final String? category;
  const FilePickerScreen({super.key, this.category});
  @override State<FilePickerScreen> createState() => _FilePickerScreenState();
}

class _FilePickerScreenState extends State<FilePickerScreen>
    with TickerProviderStateMixin {

  late TabController _tabs;
  final Set<String>  _selectedIds  = {};  // asset IDs or file paths

  bool _loading = true;

  // media (photos/videos)
  AssetPathEntity?       _curAlbum;
  List<AssetEntity>      _assets   = [];

  // filesystem
  List<File>           _files    = [];
  Map<String, AppInfo> _appInfoMap = {};

  // contacts
  List<Contact> _contacts = [];

  late List<_TabDef> _tabDefs;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabDefs = _buildTabs();
    _tabs    = TabController(length: _tabDefs.length, vsync: this)
      ..addListener(() {
        if (!_tabs.indexIsChanging) {
          _tabIndex = _tabs.index;
          _loadTab(_tabIndex);
        }
      });
    _loadTab(0);
  }

  List<_TabDef> _buildTabs() {
    final cat = widget.category;
    if (cat == null || cat == 'All Files') {
      return const [
        _TabDef('Photos',    Icons.image_rounded,       Color(0xFF4E8FFF)),
        _TabDef('Videos',    Icons.videocam_rounded,    Color(0xFFFF4E6A)),
        _TabDef('Music',     Icons.music_note_rounded,  Color(0xFF9B6BFF)),
        _TabDef('Apps',      Icons.android_rounded,     Color(0xFF2DC97E)),
        _TabDef('Documents', Icons.description_rounded, Color(0xFFFF9B2F)),
        _TabDef('Contacts',  Icons.contacts_rounded,    Color(0xFF3BBFFF)),
      ];
    }
    return [_tabForCategory(cat)];
  }

  _TabDef _tabForCategory(String cat) {
    switch (cat) {
      case 'Photos':    return const _TabDef('Photos',    Icons.image_rounded,       Color(0xFF4E8FFF));
      case 'Videos':    return const _TabDef('Videos',    Icons.videocam_rounded,    Color(0xFFFF4E6A));
      case 'Music':     return const _TabDef('Music',     Icons.music_note_rounded,  Color(0xFF9B6BFF));
      case 'Apps':      return const _TabDef('Apps',      Icons.android_rounded,     Color(0xFF2DC97E));
      case 'Documents': return const _TabDef('Documents', Icons.description_rounded, Color(0xFFFF9B2F));
      case 'Contacts':  return const _TabDef('Contacts',  Icons.contacts_rounded,    Color(0xFF3BBFFF));
      default:          return const _TabDef('Files',     Icons.folder_rounded,      Color(0xFF3BBFFF));
    }
  }

  Future<void> _loadTab(int idx) async {
    setState(() => _loading = true);
    final tab = _tabDefs[idx];
    switch (tab.label) {
      case 'Photos': await _loadMedia(RequestType.image); break;
      case 'Videos': await _loadMedia(RequestType.video); break;
      case 'Music':  await _loadFs(['mp3','aac','wav','flac','m4a','ogg','opus']); break;
      case 'Apps':   await _loadApks(); break;
      case 'Documents': await _loadFs(['pdf','doc','docx','xls','xlsx','ppt','pptx','txt','csv']); break;
      case 'Contacts':  await _loadContacts(); break;
      default:          await _loadFs(null); break;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadMedia(RequestType type) async {
    final res = await PhotoManager.requestPermissionExtend();
    if (!res.hasAccess) return;
    final albums = await PhotoManager.getAssetPathList(type: type);
    if (albums.isEmpty) return;
    _curAlbum = albums.first;
    final cnt  = await _curAlbum!.assetCountAsync;
    _assets    = await _curAlbum!.getAssetListRange(start: 0, end: cnt);
  }

  Future<void> _loadFs(List<String>? exts) async {
    final roots = [Directory('/storage/emulated/0'), Directory('/sdcard')];
    final found = <File>[];
    for (final root in roots) {
      if (!await root.exists()) continue;
      try {
        await for (final e in root.list(recursive: true, followLinks: false)) {
          if (e is File) {
            if (exts == null) {
              found.add(e);
            } else {
              final ext = p.extension(e.path).replaceAll('.', '').toLowerCase();
              if (exts.contains(ext)) found.add(e);
            }
          }
        }
      } catch (_) {}
    }
    final seen = <String>{};
    _files = found.where((f) => seen.add(f.path)).toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  }

  Future<void> _loadApks() async {
    await _loadFs(['apk']);
    if (!Platform.isAndroid) return;
    try {
      final apps = await InstalledApps.getInstalledApps(true, true);
      final map  = <String, AppInfo>{};
      for (final f in _files) {
        final base = p.basenameWithoutExtension(f.path).toLowerCase();
        for (final app in apps) {
          if (base.contains(app.packageName.toLowerCase()) ||
              base.contains(app.name.toLowerCase())) {
            map[f.path] = app;
            break;
          }
        }
      }
      _appInfoMap = map;
    } catch (_) {}
  }

  Future<void> _loadContacts() async {
    _contacts = await ContactService().loadContacts();
  }

  Future<void> _confirm() async {
    final paths = <String>[];

    // Resolve photo/video assets to actual file paths
    for (final asset in _assets) {
      if (_selectedIds.contains(asset.id)) {
        final file = await asset.file;
        if (file != null) paths.add(file.path);
      }
    }

    // Filesystem files selected directly
    for (final f in _files) {
      if (_selectedIds.contains(f.path)) paths.add(f.path);
    }

    // Contacts → export VCF then add path
    final selContacts = _contacts
        .where((c) => _selectedIds.contains(c.id))
        .toList();
    if (selContacts.isNotEmpty) {
      final vcfPath = await ContactService().exportToVcf(selContacts);
      paths.add(vcfPath);
    }

    if (mounted) Navigator.pop(context, paths);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBlue,
        foregroundColor: _kWhite,
        elevation: 0,
        title: const Text('Select Files',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (_selectedIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: _confirm,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _kWhite,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Add ${_selectedIds.length}',
                      style: const TextStyle(
                          color: _kBlue, fontWeight: FontWeight.w800)),
                ),
              ),
            ),
        ],
        bottom: _tabDefs.length > 1
            ? TabBar(
                controller: _tabs,
                isScrollable: true,
                indicatorColor: _kWhite,
                labelColor: _kWhite,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: _tabDefs.map((t) => Tab(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(t.icon, size: 15),
                    const SizedBox(width: 5),
                    Text(t.label),
                  ]),
                )).toList(),
              )
            : null,
      ),
      body: _tabDefs.length > 1
          ? TabBarView(
              controller: _tabs,
              physics: const NeverScrollableScrollPhysics(),
              children: _tabDefs.map((_) => _buildTabBody(_tabIndex)).toList(),
            )
          : _buildTabBody(0),
      bottomNavigationBar: _selectedIds.isEmpty ? null : _buildBottomBar(),
    );
  }

  Widget _buildTabBody(int idx) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(
          color: _tabDefs[idx].color));
    }
    final tab = _tabDefs[idx];
    if (tab.label == 'Contacts') return _buildContactsList(tab);
    if (tab.label == 'Photos' || tab.label == 'Videos') {
      return _assets.isEmpty
          ? _buildEmpty(tab)
          : _buildMediaGrid(tab);
    }
    return _files.isEmpty ? _buildEmpty(tab) : _buildFilesList(tab);
  }

  Widget _buildMediaGrid(_TabDef tab) {
    return GridView.builder(
      padding: const EdgeInsets.all(3),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 3, mainAxisSpacing: 3),
      itemCount: _assets.length,
      itemBuilder: (_, i) {
        final asset = _assets[i];
        final sel   = _selectedIds.contains(asset.id);
        final num   = _selectedIds.toList().indexOf(asset.id) + 1;
        return GestureDetector(
          onTap: () => setState(() =>
              sel ? _selectedIds.remove(asset.id) : _selectedIds.add(asset.id)),
          child: Stack(fit: StackFit.expand, children: [
            FutureBuilder<Uint8List?>(
              future: asset.thumbnailDataWithSize(const ThumbnailSize.square(300)),
              builder: (_, snap) => snap.data != null
                  ? Image.memory(snap.data!, fit: BoxFit.cover)
                  : Container(color: const Color(0xFFEDF3FF)),
            ),
            if (sel) Container(color: _kBlue.withValues(alpha: 0.3)),
            Positioned(top: 6, right: 6,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: sel ? _kBlue : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: sel ? _kBlue : _kWhite, width: 2),
                ),
                child: sel
                    ? Center(child: Text('$num',
                        style: const TextStyle(color: _kWhite,
                            fontSize: 10, fontWeight: FontWeight.w900)))
                    : null,
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildFilesList(_TabDef tab) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 80),
      itemCount: _files.length,
      itemBuilder: (_, i) {
        final f    = _files[i];
        final app  = _appInfoMap[f.path];
        final name = app?.name ?? p.basename(f.path);
        final sel  = _selectedIds.contains(f.path);
        final ext  = app != null ? 'APK'
            : p.extension(f.path).replaceAll('.', '').toUpperCase();
        final bytes = f.lengthSync();
        final size  = bytes < 1024 * 1024
            ? '${(bytes / 1024).toStringAsFixed(1)} KB'
            : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

        return GestureDetector(
          onTap: () => setState(() =>
              sel ? _selectedIds.remove(f.path) : _selectedIds.add(f.path)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sel ? tab.color.withValues(alpha: 0.07) : _kWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: sel ? tab.color : _kBord, width: sel ? 1.5 : 1),
            ),
            child: Row(children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                    color: tab.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: app?.icon != null && app!.icon!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(app.icon!, fit: BoxFit.cover))
                    : Icon(tab.icon, color: tab.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _kText,
                        fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: tab.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(ext, style: TextStyle(
                        color: tab.color, fontSize: 9, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 8),
                  Text(size, style: const TextStyle(color: _kSub, fontSize: 11)),
                ]),
              ])),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: sel ? tab.color : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: sel ? tab.color : _kSub, width: 2),
                ),
                child: sel
                    ? const Icon(Icons.check_rounded, color: _kWhite, size: 14)
                    : null,
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildContactsList(_TabDef tab) {
    if (_contacts.isEmpty) return _buildEmpty(tab);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 80),
      itemCount: _contacts.length,
      itemBuilder: (_, i) {
        final c   = _contacts[i];
        final sel = _selectedIds.contains(c.id);
        return GestureDetector(
          onTap: () => setState(() =>
              sel ? _selectedIds.remove(c.id) : _selectedIds.add(c.id)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: sel ? tab.color.withValues(alpha: 0.07) : _kWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: sel ? tab.color : _kBord),
            ),
            child: Row(children: [
              CircleAvatar(
                backgroundColor: tab.color.withValues(alpha: 0.12),
                radius: 22,
                child: Text(c.displayName.isNotEmpty ? c.displayName[0] : '?',
                    style: TextStyle(color: tab.color,
                        fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.displayName,
                    style: const TextStyle(color: _kText,
                        fontSize: 13, fontWeight: FontWeight.w600)),
                if (c.phones.isNotEmpty)
                  Text(c.phones.first.number,
                      style: const TextStyle(color: _kSub, fontSize: 12)),
              ])),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 24, height: 24,
                decoration: BoxDecoration(
                  color: sel ? tab.color : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: sel ? tab.color : _kSub, width: 2),
                ),
                child: sel
                    ? const Icon(Icons.check_rounded, color: _kWhite, size: 14)
                    : null,
              ),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(_TabDef tab) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(
            color: tab.color.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(tab.icon, color: tab.color, size: 36),
      ),
      const SizedBox(height: 14),
      Text('No ${tab.label} found',
          style: const TextStyle(color: _kText,
              fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      Text('${tab.label} on your device will appear here',
          style: const TextStyle(color: _kSub, fontSize: 13)),
    ]),
  );

  Widget _buildBottomBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: const BoxDecoration(
          color: _kWhite,
          boxShadow: [BoxShadow(
            color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4))],
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: _kBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text('${_selectedIds.length}',
                style: const TextStyle(color: _kBlue,
                    fontSize: 16, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('items selected',
              style: TextStyle(color: _kText,
                  fontSize: 14, fontWeight: FontWeight.w600))),
          GestureDetector(
            onTap: _confirm,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF3461FF), Color(0xFF5B8BFF)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('Add Files',
                  style: TextStyle(color: _kWhite,
                      fontSize: 14, fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  void dispose() { _tabs.dispose(); super.dispose(); }
}

class _TabDef {
  final String label;
  final IconData icon;
  final Color color;
  const _TabDef(this.label, this.icon, this.color);
}
