import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../services/transfer_service.dart';
import '../../services/connection_service.dart';
import '../../data/models/transfer_record_model.dart';
import 'scan_screen.dart';

class SelectFilesScreen extends StatefulWidget {
  final int initialTab;
  const SelectFilesScreen({super.key, this.initialTab = 0});

  @override
  State<SelectFilesScreen> createState() => _SelectFilesScreenState();
}

class _SelectFilesScreenState extends State<SelectFilesScreen>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;

  static const _tabs = ['RECENT', 'CONTACTS', 'FILES', 'VIDEOS', 'APPS', 'PHOTOS', 'MUSIC'];

  static const _kBlue  = Color(0xFF2196F3);
  static const _kText  = Color(0xFF212121);
  static const _kSub   = Color(0xFF757575);
  static const _kBg    = Color(0xFFF5F5F5);
  static const _kWhite = Colors.white;

  final Set<String> _selected = {};

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this,
        initialIndex: widget.initialTab.clamp(0, _tabs.length - 1));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kWhite,
        foregroundColor: _kText,
        elevation: 0,
        leading: const BackButton(color: _kText),
        title: const Text('Select Files',
            style: TextStyle(color: _kText, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: _kText), onPressed: () {}),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            decoration: const BoxDecoration(
              color: _kWhite,
              border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
            ),
            child: TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              labelColor: _kBlue,
              unselectedLabelColor: _kSub,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
              indicatorColor: _kBlue,
              indicatorWeight: 2,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _RecentTab(selected: _selected, onChanged: _refresh),
          _ContactsTab(selected: _selected, onChanged: _refresh),
          _FilesTab(selected: _selected, onChanged: _refresh),
          _VideosTab(selected: _selected, onChanged: _refresh),
          _AppsTab(selected: _selected, onChanged: _refresh),
          _PhotosTab(selected: _selected, onChanged: _refresh),
          _MusicTab(selected: _selected, onChanged: _refresh),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  void _refresh() => setState(() {});

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.only(
          left: 20, right: 16, top: 12,
          bottom: MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: _kWhite,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 1)),
      ),
      child: Row(children: [
        Text('${_selected.length} file(s) selected',
            style: const TextStyle(color: _kSub, fontSize: 14)),
        const Spacer(),
        SizedBox(
          width: 140,
          height: 44,
          child: ElevatedButton(
            onPressed: () async {
              if (_selected.isEmpty) return;

              // Show loading indicator while resolving paths
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Preparing files...',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              final List<String> resolvedPaths = [];
              for (final item in _selected) {
                if (File(item).existsSync()) {
                  resolvedPaths.add(item);
                  continue;
                }
                // 1. Try asset ID (Photos/Videos)
                try {
                  final asset = await AssetEntity.fromId(item);
                  if (asset != null) {
                    final f = await asset.file;
                    if (f != null && f.existsSync()) {
                      resolvedPaths.add(f.path);
                      continue;
                    }
                  }
                } catch (_) {}

                // 2. Try installed app package name
                try {
                  final apkPath = await ConnectionService().getApkPath(item);
                  if (apkPath != null &&
                      apkPath.isNotEmpty &&
                      File(apkPath).existsSync()) {
                    resolvedPaths.add(apkPath);
                    continue;
                  }
                } catch (_) {}
              }

              if (mounted) Navigator.pop(context); // Close loading dialog

              if (resolvedPaths.isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not access selected file paths.')),
                  );
                }
                return;
              }

              TransferService().clearQueue();
              TransferService().addFiles(resolvedPaths);
              if (!mounted) return;
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ScanScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: _kWhite,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('NEXT', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          ),
        ),
      ]),
    );
  }
}

// ─── RECENT tab ───────────────────────────────────────────────────────────────
class _RecentTab extends StatefulWidget {
  final Set<String> selected;
  final VoidCallback onChanged;
  const _RecentTab({required this.selected, required this.onChanged});
  @override
  State<_RecentTab> createState() => _RecentTabState();
}

class _RecentTabState extends State<_RecentTab> {
  int _seg = 0; // 0=Received, 1=Sent
  List<TransferRecord> _records = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final r = await TransferService().loadHistory();
    if (mounted) setState(() { _records = r; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _buildSegment(),
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent()),
    ]);
  }

  Widget _buildSegment() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Container(
        decoration: BoxDecoration(color: const Color(0xFFEEEEEE),
            borderRadius: BorderRadius.circular(8)),
        height: 40,
        child: Row(children: [
          _Seg(label: 'Received', active: _seg == 0,
              onTap: () => setState(() => _seg = 0)),
          _Seg(label: 'Sent', active: _seg == 1,
              onTap: () => setState(() => _seg = 1)),
        ]),
      ),
    );
  }

  Widget _buildContent() {
    final dir = _seg == 0 ? TransferDirection.received : TransferDirection.sent;
    final list = _records.where((r) => r.direction == dir).toList();
    if (list.isEmpty) return _buildEmpty();
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final r = list[i];
        return _RecordTile(record: r);
      },
    );
  }

  Widget _buildEmpty() {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      _NoFileIllustration(),
      const SizedBox(height: 12),
      const Text('No file', style: TextStyle(color: Color(0xFF757575), fontSize: 14)),
    ]));
  }
}

// ─── CONTACTS tab ─────────────────────────────────────────────────────────────
class _ContactsTab extends StatefulWidget {
  final Set<String> selected;
  final VoidCallback onChanged;
  const _ContactsTab({required this.selected, required this.onChanged});
  @override
  State<_ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<_ContactsTab> {
  bool _granted = false;
  bool _checked = false;
  List<Contact> _contacts = [];

  @override
  void initState() { super.initState(); _check(); }

  Future<void> _check() async {
    final s = await Permission.contacts.status;
    if (s.isGranted) { await _load(); }
    if (mounted) setState(() { _granted = s.isGranted; _checked = true; });
  }

  Future<void> _load() async {
    final c = await FlutterContacts.getContacts(withProperties: true);
    if (mounted) setState(() { _contacts = c; _granted = true; });
  }

  Future<void> _allow() async {
    final s = await Permission.contacts.request();
    if (s.isGranted) await _load();
    if (mounted) setState(() => _granted = s.isGranted);
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) return const Center(child: CircularProgressIndicator());
    if (!_granted) {
      return Center(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _ContactsIllustration(),
          const SizedBox(height: 16),
          const Text('To share contacts with friend , please allow permission to access Contacts',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF757575), fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: _allow,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD6EAF8),
                foregroundColor: const Color(0xFF2196F3),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('ALLOW', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ]),
      ));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _contacts.length,
      itemBuilder: (_, i) {
        final c = _contacts[i];
        final sel = widget.selected.contains(c.id);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFFE3F0FF),
            child: Text(c.displayName.isNotEmpty ? c.displayName[0] : '?',
                style: const TextStyle(color: Color(0xFF2196F3), fontWeight: FontWeight.w700)),
          ),
          title: Text(c.displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: c.phones.isNotEmpty ? Text(c.phones.first.number, style: const TextStyle(fontSize: 12)) : null,
          trailing: _CircleCheck(selected: sel),
          onTap: () {
            if (sel) widget.selected.remove(c.id);
            else widget.selected.add(c.id);
            widget.onChanged();
          },
        );
      },
    );
  }
}

// ─── FILES tab ────────────────────────────────────────────────────────────────
class _FilesTab extends StatefulWidget {
  final Set<String> selected;
  final VoidCallback onChanged;
  const _FilesTab({required this.selected, required this.onChanged});
  @override
  State<_FilesTab> createState() => _FilesTabState();
}

class _FilesTabState extends State<_FilesTab> {
  double _usedGb = 0, _totalGb = 0;
  bool _storageGranted = false;
  bool _storageChecked = false;

  @override
  void initState() {
    super.initState();
    _checkStorage();
  }

  Future<void> _checkStorage() async {
    bool granted = false;
    if (Platform.isAndroid) {
      // Android 11+ needs MANAGE_EXTERNAL_STORAGE for full file access
      final sdkInt = await _getSdkInt();
      if (sdkInt >= 30) {
        granted = await Permission.manageExternalStorage.isGranted;
      } else {
        granted = await Permission.storage.isGranted;
      }
    } else {
      granted = true;
    }
    if (mounted) setState(() { _storageGranted = granted; _storageChecked = true; });
    if (granted) _loadStorage();
  }

  Future<int> _getSdkInt() async {
    try {
      final r = await Process.run('getprop', ['ro.build.version.sdk']);
      return int.tryParse((r.stdout as String).trim()) ?? 0;
    } catch (_) { return 0; }
  }

  Future<void> _requestStorage() async {
    if (Platform.isAndroid) {
      final sdkInt = await _getSdkInt();
      if (sdkInt >= 30) {
        // MANAGE_EXTERNAL_STORAGE opens the system "All files access" settings page
        await Permission.manageExternalStorage.request();
      } else {
        await Permission.storage.request();
      }
    }
    _checkStorage();
  }

  Future<void> _loadStorage() async {
    try {
      final r = await Process.run('df', ['-k', '/storage/emulated/0']);
      final lines = (r.stdout as String).split('\n');
      if (lines.length > 1) {
        final parts = lines[1].trim().split(RegExp(r'\s+'));
        if (parts.length >= 4) {
          final total = double.tryParse(parts[1]) ?? 0;
          final used  = double.tryParse(parts[2]) ?? 0;
          if (mounted) setState(() {
            _totalGb = total / (1024 * 1024);
            _usedGb  = used  / (1024 * 1024);
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!_storageChecked) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!_storageGranted) {
      return _buildStoragePermissionPlaceholder();
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        _buildWhatsAppCard(),
        const SizedBox(height: 10),
        _buildDocumentsCard(),
        const SizedBox(height: 10),
        _buildRowTile(
          icon: Icons.folder_zip_rounded, iconColor: const Color(0xFF1877F2),
          iconBgColor: const Color(0xFFE3F2FD),
          title: 'Zip', subtitle: 'zip, rar, iso, 7z',
          extensions: ['zip','rar','iso','7z'], minBytes: 0),
        const SizedBox(height: 8),
        _buildRowTile(
          icon: Icons.folder_rounded, iconColor: const Color(0xFFFF9800),
          iconBgColor: const Color(0xFFFFF3E0),
          title: 'Large Files', subtitle: 'Larger than 50MB',
          extensions: const [], minBytes: 50 * 1024 * 1024),
        const SizedBox(height: 8),
        _buildStorageRow(),
      ]),
    );
  }

  // ── Storage permission placeholder — shown when MANAGE_EXTERNAL_STORAGE not granted ──
  Widget _buildStoragePermissionPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFE3F0FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.folder_open_rounded,
                  color: Color(0xFF2196F3), size: 40),
            ),
            const SizedBox(height: 16),
            const Text(
              'Allow access to manage all files',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF212121),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Allow this app to read, modify and delete all files on this device or any connected storage volumes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF757575), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _requestStorage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('ALLOW',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
                        letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('WhatsApp Transfer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _WaTile(
            color: const Color(0xFF25D366), icon: Icons.sync_rounded,
            title: 'Status', subtitle: '0')),
          const SizedBox(width: 10),
          Expanded(child: _WaTile(
            color: const Color(0xFFFF7043), icon: Icons.perm_media_rounded,
            title: 'Media', subtitle: '')),
        ]),
      ]),
    );
  }

  Widget _buildDocumentsCard() {
    final docs = [
      _DocType('ALL',   Icons.folder_rounded,         const Color(0xFFFF9800), const Color(0xFFFFF3E0), null),
      _DocType('PDF',   Icons.picture_as_pdf_rounded, const Color(0xFFE53935), const Color(0xFFFFEBEE), ['pdf']),
      _DocType('EXCEL', Icons.grid_on_rounded,        const Color(0xFF43A047), const Color(0xFFE8F5E9), ['xls','xlsx','csv']),
      _DocType('PPT',   Icons.slideshow_rounded,      const Color(0xFFFF7043), const Color(0xFFFFF3E0), ['ppt','pptx']),
      _DocType('TXT',   Icons.text_snippet_rounded,   const Color(0xFF7E57C2), const Color(0xFFEDE7F6), ['txt']),
      _DocType('DOC',   Icons.description_rounded,    const Color(0xFF1E88E5), const Color(0xFFE3F2FD), ['doc','docx']),
      _DocType('WPS',   Icons.article_rounded,        const Color(0xFF00ACC1), const Color(0xFFE0F7FA), ['wps']),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, childAspectRatio: 0.9,
            mainAxisSpacing: 12, crossAxisSpacing: 8),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final d = docs[i];
            return GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => _FileListScreen(
                  title: d.label == 'ALL' ? 'All Documents' : d.label,
                  extensions: d.extensions ?? ['pdf','doc','docx','xls','xlsx',
                      'ppt','pptx','txt','csv','wps'],
                  selected: widget.selected,
                  onChanged: widget.onChanged,
                ),
              )),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: d.bgColor,
                    borderRadius: BorderRadius.circular(10)),
                  child: Icon(d.icon, color: d.color, size: 28)),
                const SizedBox(height: 5),
                Text(d.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ]),
            );
          },
        ),
      ]),
    );
  }

  Widget _buildRowTile({required IconData icon, required Color iconColor,
      Color? iconBgColor, required String title, required String subtitle,
      required List<String> extensions, required int minBytes}) {
    return GestureDetector(
      onTap: () {
        final ctx = context;
        Navigator.push(ctx, MaterialPageRoute(
          builder: (_) => _FileListScreen(
            title: title,
            extensions: extensions,
            minBytes: minBytes,
            selected: widget.selected,
            onChanged: widget.onChanged,
          ),
        ));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
                color: iconBgColor ?? iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(subtitle, style: const TextStyle(color: Color(0xFF757575), fontSize: 12)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFBDBDBD)),
        ]),
      ),
    );
  }

  Widget _buildStorageRow() {
    final usedPct = _totalGb > 0 ? (_usedGb / _totalGb).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(color: const Color(0xFFE3F0FF),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.storage_rounded, color: Color(0xFF1877F2), size: 24)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Internal shared storage', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 4),
          Row(children: [
            Text('${_usedGb.toStringAsFixed(2)}GB',
                style: const TextStyle(color: Color(0xFF2196F3), fontSize: 12, fontWeight: FontWeight.w600)),
            Text('/${_totalGb.toStringAsFixed(2)}GB',
                style: const TextStyle(color: Color(0xFF757575), fontSize: 12)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: usedPct, minHeight: 6,
              backgroundColor: const Color(0xFFEEEEEE),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2196F3)))),
        ])),
        const SizedBox(width: 8),
        const Icon(Icons.chevron_right_rounded, color: Color(0xFFBDBDBD)),
      ]),
    );
  }
}

// ─── VIDEOS tab ───────────────────────────────────────────────────────────────
class _VideosTab extends StatefulWidget {
  final Set<String> selected;
  final VoidCallback onChanged;
  const _VideosTab({required this.selected, required this.onChanged});
  @override
  State<_VideosTab> createState() => _VideosTabState();
}

class _VideosTabState extends State<_VideosTab> {
  static const _pageSize = 60;

  int _seg = 1; // 0=Safebox, 1=Recent, 2=Folders
  AssetPathEntity? _album;
  List<AssetEntity> _videos = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _totalCount = 0;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400 &&
        !_loadingMore && _hasMore) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    final res = await PhotoManager.requestPermissionExtend();
    if (!res.hasAccess) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final albums = await PhotoManager.getAssetPathList(type: RequestType.video);
    if (albums.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    _album = albums.first;
    _totalCount = await _album!.assetCountAsync;
    final first = await _album!.getAssetListRange(
        start: 0, end: _pageSize.clamp(0, _totalCount));
    if (mounted) {
      setState(() {
        _videos = first;
        _hasMore = first.length < _totalCount;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_album == null || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    final next = await _album!.getAssetListRange(
        start: _videos.length,
        end: (_videos.length + _pageSize).clamp(0, _totalCount));
    if (mounted) {
      setState(() {
        _videos.addAll(next);
        _hasMore = _videos.length < _totalCount;
        _loadingMore = false;
      });
    }
  }

  Map<String, List<AssetEntity>> _groupByDate() {
    final now = DateTime.now();
    final groups = <String, List<AssetEntity>>{};
    for (final v in _videos) {
      final dt = v.createDateTime;
      final diff = now.difference(dt).inDays;
      String label;
      if (diff == 0) label = 'Today';
      else if (diff == 1) label = 'Yesterday';
      else if (diff == 2) label = 'The day before yesterday';
      else label = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      (groups[label] ??= []).add(v);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Container(
          decoration: BoxDecoration(color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(8)),
          height: 40,
          child: Row(children: [
            _Seg(label: 'Safebox', active: _seg == 0, onTap: () => setState(() => _seg = 0)),
            _Seg(label: 'Recent',  active: _seg == 1, onTap: () => setState(() => _seg = 1)),
            _Seg(label: 'Folders', active: _seg == 2, onTap: () => setState(() => _seg = 2)),
          ]),
        ),
      ),
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _seg == 1 ? _buildRecent() : _buildPlaceholder()),
    ]);
  }

  Widget _buildRecent() {
    if (_videos.isEmpty) return _buildPlaceholder();
    final groups = _groupByDate();
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.all(12),
      children: [
        ...groups.entries.map((e) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(children: [
                  const Icon(Icons.expand_less_rounded, size: 18, color: Color(0xFF2196F3)),
                  const SizedBox(width: 4),
                  Text('${e.key} (${e.value.length})',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const Spacer(),
                  _CircleCheck(selected: false),
                ]),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, crossAxisSpacing: 3, mainAxisSpacing: 3),
              itemCount: e.value.length,
              itemBuilder: (_, i) {
                final asset = e.value[i];
                final sel = widget.selected.contains(asset.id);
                final dur = asset.videoDuration;
                final mm = dur.inMinutes.remainder(60).toString().padLeft(2, '0');
                final ss = dur.inSeconds.remainder(60).toString().padLeft(2, '0');
                return GestureDetector(
                  onTap: () {
                    if (sel) widget.selected.remove(asset.id);
                    else widget.selected.add(asset.id);
                    widget.onChanged();
                  },
                  child: Stack(children: [
                    Positioned.fill(child: FutureBuilder<Uint8List?>(
                      future: asset.thumbnailDataWithSize(const ThumbnailSize.square(200)),
                      builder: (_, s) => s.data != null
                          ? Image.memory(s.data!, fit: BoxFit.cover)
                          : Container(color: const Color(0xFF424242)),
                    )),
                    Positioned(top: 4, right: 4, child: _CircleCheck(selected: sel)),
                    Positioned(bottom: 4, right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                        child: Text('$mm:$ss',
                            style: const TextStyle(color: Colors.white, fontSize: 10)))),
                  ]),
                );
              },
            ),
          ]),
        );
        }),
        if (_loadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      ],
    );
  }

  Widget _buildPlaceholder() => const Center(
      child: Text('Coming Soon', style: TextStyle(color: Color(0xFF757575))));
}

// ─── APPS tab ─────────────────────────────────────────────────────────────────
class _AppsTab extends StatefulWidget {
  final Set<String> selected;
  final VoidCallback onChanged;
  const _AppsTab({required this.selected, required this.onChanged});
  @override
  State<_AppsTab> createState() => _AppsTabState();
}

class _AppsTabState extends State<_AppsTab> {
  static const _pageSize = 40;

  int _seg = 0;
  List<AppInfo> _allApps = [];  // full list loaded once
  List<AppInfo> _newApps = [];
  List<AppInfo> _otherApps = [];

  // paginated slices rendered in the grid
  int _newVisible = 0;
  int _othersVisible = 0;

  bool _loading = true;
  bool _loadingMore = false;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400 &&
        !_loadingMore) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    try {
      final apps = await InstalledApps.getInstalledApps(true, true);
      final now = DateTime.now();
      final newList = apps.where((a) {
        return now.difference(
            DateTime.fromMillisecondsSinceEpoch(a.installedTimestamp)).inDays <= 7;
      }).toList();
      final otherList = apps.where((a) {
        return now.difference(
            DateTime.fromMillisecondsSinceEpoch(a.installedTimestamp)).inDays > 7;
      }).toList();

      if (mounted) {
        setState(() {
          _allApps    = apps;
          _newApps    = newList;
          _otherApps  = otherList;
          // Show first page immediately
          _newVisible    = _newApps.length.clamp(0, _pageSize);
          _othersVisible = _otherApps.length.clamp(0, _pageSize - _newVisible);
          _loading    = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _loadMore() {
    final totalVisible = _newVisible + _othersVisible;
    final totalAll     = _newApps.length + _otherApps.length;
    if (totalVisible >= totalAll) return;

    setState(() => _loadingMore = true);

    // Fill new-apps slice first, then others
    int toAdd = _pageSize;
    int newV = _newVisible;
    int otherV = _othersVisible;

    final newRemain = _newApps.length - newV;
    if (newRemain > 0) {
      final addNew = toAdd.clamp(0, newRemain);
      newV += addNew;
      toAdd -= addNew;
    }
    if (toAdd > 0) {
      final addOther = toAdd.clamp(0, _otherApps.length - otherV);
      otherV += addOther;
    }

    setState(() {
      _newVisible    = newV;
      _othersVisible = otherV;
      _loadingMore   = false;
    });
  }

  bool get _hasMore =>
      (_newVisible < _newApps.length) || (_othersVisible < _otherApps.length);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Container(
          decoration: BoxDecoration(color: const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            _Seg(label: 'Installed',     active: _seg == 0, onTap: () => setState(() => _seg = 0)),
            _Seg(label: 'Not Installed', active: _seg == 1, onTap: () => setState(() => _seg = 1)),
          ]),
        ),
      ),
      Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _seg == 0 ? _buildInstalled() : _buildPlaceholder()),
    ]);
  }

  Widget _buildInstalled() {
    if (_allApps.isEmpty) {
      return const Center(child: Text('No apps found',
          style: TextStyle(color: Color(0xFF757575))));
    }

    final visibleNew    = _newApps.sublist(0, _newVisible);
    final visibleOthers = _otherApps.sublist(0, _othersVisible);

    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.all(12),
      children: [
        if (visibleNew.isNotEmpty) ...[
          _buildGroupHeader('New', _newApps.length),
          _buildAppGrid(visibleNew),
          const SizedBox(height: 12),
        ],
        _buildGroupHeader('Apps', _otherApps.length),
        _buildAppGrid(visibleOthers),
        if (_hasMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
      ],
    );
  }

  Widget _buildGroupHeader(String label, int totalCount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        const Icon(Icons.expand_less_rounded, size: 18, color: Color(0xFF2196F3)),
        const SizedBox(width: 4),
        Text('$label ($totalCount)',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const Spacer(),
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            color: Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF9E9E9E), width: 1.5)),
        ),
      ]),
    );
  }

  Widget _buildAppGrid(List<AppInfo> list) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, childAspectRatio: 0.72,
          crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: list.length,
      itemBuilder: (_, i) {
        final app = list[i];
        final sel = widget.selected.contains(app.packageName);
        return GestureDetector(
          onTap: () {
            if (sel) widget.selected.remove(app.packageName);
            else widget.selected.add(app.packageName);
            widget.onChanged();
          },
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(alignment: Alignment.topRight, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: app.icon != null && app.icon!.isNotEmpty
                    ? Image.memory(app.icon!, width: 56, height: 56, fit: BoxFit.cover)
                    : Container(width: 56, height: 56,
                        decoration: BoxDecoration(
                            color: const Color(0xFFE3F0FF),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.android_rounded,
                            color: Color(0xFF2196F3), size: 32)),
              ),
              if (sel)
                const Positioned(top: 0, right: 0,
                    child: Icon(Icons.check_circle_rounded,
                        color: Color(0xFF2196F3), size: 16)),
            ]),
            const SizedBox(height: 4),
            Text(app.name,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center, maxLines: 2,
                overflow: TextOverflow.ellipsis),
            Text(app.versionName,
                style: const TextStyle(fontSize: 9, color: Color(0xFF757575)),
                textAlign: TextAlign.center),
          ]),
        );
      },
    );
  }

  Widget _buildPlaceholder() => const Center(
      child: Text('Coming Soon', style: TextStyle(color: Color(0xFF757575))));
}

// ─── PHOTOS tab ───────────────────────────────────────────────────────────────
class _PhotosTab extends StatefulWidget {
  final Set<String> selected;
  final VoidCallback onChanged;
  const _PhotosTab({required this.selected, required this.onChanged});
  @override
  State<_PhotosTab> createState() => _PhotosTabState();
}

class _PhotosTabState extends State<_PhotosTab> {
  static const _pageSize = 60;

  AssetPathEntity? _album;
  List<AssetEntity> _photos = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _totalCount = 0;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300 &&
        !_loadingMore && _hasMore) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    final res = await PhotoManager.requestPermissionExtend();
    if (!res.hasAccess) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    if (albums.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    _album = albums.first;
    _totalCount = await _album!.assetCountAsync;
    final first = await _album!.getAssetListRange(
        start: 0, end: _pageSize.clamp(0, _totalCount));
    if (mounted) {
      setState(() {
        _photos = first;
        _hasMore = first.length < _totalCount;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_album == null || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    final next = await _album!.getAssetListRange(
        start: _photos.length,
        end: (_photos.length + _pageSize).clamp(0, _totalCount));
    if (mounted) {
      setState(() {
        _photos.addAll(next);
        _hasMore = _photos.length < _totalCount;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_photos.isEmpty) return const Center(child: Text('No photos',
        style: TextStyle(color: Color(0xFF757575))));
    // +1 for the loading footer row when more items exist
    final itemCount = _photos.length + (_hasMore ? 1 : 0);
    return GridView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(3),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 3, mainAxisSpacing: 3),
      itemCount: itemCount,
      itemBuilder: (_, i) {
        // Footer spinner
        if (i == _photos.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        final asset = _photos[i];
        final sel = widget.selected.contains(asset.id);
        final num = widget.selected.toList().indexOf(asset.id) + 1;
        return GestureDetector(
          onTap: () {
            if (sel) widget.selected.remove(asset.id);
            else widget.selected.add(asset.id);
            widget.onChanged();
          },
          child: Stack(fit: StackFit.expand, children: [
            FutureBuilder<Uint8List?>(
              future: asset.thumbnailDataWithSize(const ThumbnailSize.square(200)),
              builder: (_, s) => s.data != null
                  ? Image.memory(s.data!, fit: BoxFit.cover)
                  : Container(color: const Color(0xFFEEEEEE)),
            ),
            if (sel) Container(color: const Color(0xFF2196F3).withOpacity(0.3)),
            Positioned(top: 6, right: 6,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFF2196F3) : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: sel ? const Color(0xFF2196F3) : Colors.white, width: 2)),
                child: sel ? Center(child: Text('$num',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)))
                    : null,
              )),
          ]),
        );
      },
    );
  }
}

// ─── MUSIC tab ────────────────────────────────────────────────────────────────
class _MusicTab extends StatefulWidget {
  final Set<String> selected;
  final VoidCallback onChanged;
  const _MusicTab({required this.selected, required this.onChanged});
  @override
  State<_MusicTab> createState() => _MusicTabState();
}

class _MusicTabState extends State<_MusicTab> {
  static const _pageSize = 80;

  AssetPathEntity? _album;
  List<AssetEntity> _tracks = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _totalCount = 0;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300 &&
        !_loadingMore && _hasMore) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    final res = await PhotoManager.requestPermissionExtend();
    if (!res.hasAccess) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final albums = await PhotoManager.getAssetPathList(type: RequestType.audio);
    if (albums.isEmpty) {
      if (mounted) setState(() { _loading = false; });
      return;
    }
    _album = albums.first;
    _totalCount = await _album!.assetCountAsync;
    final first = await _album!.getAssetListRange(
        start: 0, end: _pageSize.clamp(0, _totalCount));
    if (mounted) {
      setState(() {
        _tracks = first;
        _hasMore = first.length < _totalCount;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_album == null || _loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    final next = await _album!.getAssetListRange(
        start: _tracks.length,
        end: (_tracks.length + _pageSize).clamp(0, _totalCount));
    if (mounted) {
      setState(() {
        _tracks.addAll(next);
        _hasMore = _tracks.length < _totalCount;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_tracks.isEmpty) return const Center(child: Text('No music files found',
        style: TextStyle(color: Color(0xFF757575))));
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(12),
      itemCount: _tracks.length + (_hasMore ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == _tracks.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final asset = _tracks[i];
        final sel = widget.selected.contains(asset.id);
        final title = asset.title ?? p.basename(asset.relativePath ?? 'Unknown');
        final dur = asset.duration;
        final mm = (dur ~/ 60).toString().padLeft(2, '0');
        final ss = (dur % 60).toString().padLeft(2, '0');
        return ListTile(
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
                color: const Color(0xFF7E57C2).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.music_note_rounded, color: Color(0xFF7E57C2))),
          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          subtitle: Text('$mm:$ss',
              style: const TextStyle(fontSize: 11, color: Color(0xFF757575))),
          trailing: _CircleCheck(selected: sel),
          onTap: () {
            if (sel) widget.selected.remove(asset.id);
            else widget.selected.add(asset.id);
            widget.onChanged();
          },
        );
      },
    );
  }
}

// ─── Shared small widgets ─────────────────────────────────────────────────────

class _Seg extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Seg({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            boxShadow: active
                ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4)]
                : null),
          child: Center(child: Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: active ? const Color(0xFF212121) : const Color(0xFF757575)))),
        ),
      ),
    );
  }
}

class _CircleCheck extends StatelessWidget {
  final bool selected;
  const _CircleCheck({required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20, height: 20,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF2196F3) : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: selected ? const Color(0xFF2196F3) : Colors.white, width: 2)),
      child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 12) : null,
    );
  }
}

class _NoFileIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160, height: 140,
      child: Stack(alignment: Alignment.center, children: [
        Positioned(left: 20, bottom: 0,
          child: Container(width: 50, height: 60,
              decoration: BoxDecoration(color: const Color(0xFF2196F3).withOpacity(0.7),
                  borderRadius: BorderRadius.circular(6)))),
        Container(
          width: 90, height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFBDBDBD), width: 1.5),
            borderRadius: BorderRadius.circular(8)),
          child: Column(mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            const SizedBox(height: 8),
            Row(children: const [
              SizedBox(width: 8),
              _YellowBlock(), SizedBox(width: 4),
              _YellowBlock(), SizedBox(width: 4),
              _YellowBlock(), SizedBox(width: 4),
              _YellowBlock(),
            ]),
            const SizedBox(height: 8),
            Container(margin: const EdgeInsets.symmetric(horizontal: 8),
                height: 6, color: const Color(0xFFEEEEEE)),
          ]),
        ),
        Positioned(right: 0, bottom: 10,
          child: const Icon(Icons.person_rounded, size: 60, color: Color(0xFFFFB74D))),
        Positioned(right: 12, top: 10,
          child: Container(
            width: 24, height: 24,
            decoration: BoxDecoration(color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFBDBDBD))),
            child: const Center(child: Text('!',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14))))),
      ]),
    );
  }
}

class _YellowBlock extends StatelessWidget {
  const _YellowBlock();
  @override
  Widget build(BuildContext context) {
    return Container(width: 14, height: 14, color: const Color(0xFFFFB74D));
  }
}

class _ContactsIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160, height: 140,
      child: Stack(alignment: Alignment.center, children: [
        Container(
          width: 100, height: 130,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFBDBDBD), width: 1.5),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.person_rounded, color: Color(0xFF2196F3), size: 22)),
            const SizedBox(height: 8),
            const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 20),
          ])),
        Positioned(left: 0, bottom: 10,
          child: const Icon(Icons.person_rounded, size: 55, color: Color(0xFFFFB74D))),
        Positioned(top: 8, left: 10,
          child: Container(width: 50, height: 24,
              decoration: BoxDecoration(color: Colors.white,
                  border: Border.all(color: const Color(0xFFBDBDBD)),
                  borderRadius: BorderRadius.circular(4)),
              child: const Center(child: Icon(Icons.chat_bubble_outline_rounded,
                  size: 14, color: Color(0xFF757575))))),
        Positioned(top: 4, right: 4,
          child: Container(width: 10, height: 10,
              decoration: const BoxDecoration(color: Color(0xFFFF9800), shape: BoxShape.circle))),
        Positioned(bottom: 4, left: 4,
          child: Container(width: 14, height: 14,
              decoration: const BoxDecoration(color: Color(0xFFFFB74D), shape: BoxShape.circle))),
      ]),
    );
  }
}

class _WaTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String subtitle;
  const _WaTile({required this.color, required this.icon,
      required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.white, size: 20)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          if (subtitle.isNotEmpty)
            Text(subtitle, style: const TextStyle(color: Color(0xFF757575), fontSize: 11)),
        ]),
      ]),
    );
  }
}

class _DocType {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final List<String>? extensions;
  const _DocType(this.label, this.icon, this.color, this.bgColor, this.extensions);
}

class _RecordTile extends StatelessWidget {
  final TransferRecord record;
  const _RecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: const Color(0xFFE3F0FF),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.insert_drive_file_rounded,
              color: Color(0xFF2196F3), size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(record.fileName, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Text(record.sizeLabel,
              style: const TextStyle(fontSize: 11, color: Color(0xFF757575))),
        ])),
        Text('${record.timestamp.day}/${record.timestamp.month}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF757575))),
      ]),
    );
  }
}

// ─── File list screen — shown when tapping document types, Zip, Large Files ──
class _FileListScreen extends StatefulWidget {
  final String title;
  final List<String> extensions; // empty = all extensions (large files filter by minBytes)
  final int minBytes;
  final Set<String> selected;
  final VoidCallback onChanged;

  const _FileListScreen({
    required this.title,
    required this.extensions,
    this.minBytes = 0,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<_FileListScreen> createState() => _FileListScreenState();
}

class _FileListScreenState extends State<_FileListScreen> {
  static const _pageSize = 80;

  List<File> _allFiles = [];
  int _visible = 0;
  bool _loading = true;
  bool _loadingMore = false;
  final ScrollController _scroll = ScrollController();

  static const _kBlue  = Color(0xFF2196F3);
  static const _kText  = Color(0xFF212121);
  static const _kSub   = Color(0xFF757575);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400 &&
        !_loadingMore && _visible < _allFiles.length) {
      setState(() {
        _visible = (_visible + _pageSize).clamp(0, _allFiles.length);
        _loadingMore = false;
      });
    }
  }

  Future<void> _load() async {
    final found = <File>[];
    try {
      final root = Directory('/storage/emulated/0');
      if (await root.exists()) {
        await for (final entity in root.list(recursive: true, followLinks: false)) {
          if (entity is! File) continue;
          // Extension filter
          if (widget.extensions.isNotEmpty) {
            final ext = p.extension(entity.path).replaceAll('.', '').toLowerCase();
            if (!widget.extensions.contains(ext)) continue;
          }
          // Size filter (Large Files)
          if (widget.minBytes > 0) {
            try {
              if (entity.lengthSync() < widget.minBytes) continue;
            } catch (_) { continue; }
          }
          found.add(entity);
        }
      }
    } catch (_) {}
    found.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    if (mounted) {
      setState(() {
        _allFiles = found;
        _visible  = found.length.clamp(0, _pageSize);
        _loading  = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final showing = _allFiles.sublist(0, _visible);
    final hasMore = _visible < _allFiles.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _kText,
        elevation: 0,
        leading: const BackButton(color: _kText),
        title: Text(widget.title,
            style: const TextStyle(color: _kText, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: _kText), onPressed: () {}),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : showing.isEmpty
              ? Center(child: Text('No ${widget.title} files found',
                    style: const TextStyle(color: _kSub, fontSize: 14)))
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: showing.length + (hasMore ? 1 : 0),
                  itemBuilder: (_, i) {
                    if (i == showing.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }
                    final f = showing[i];
                    final sel = widget.selected.contains(f.path);
                    final name = p.basename(f.path);
                    final ext = p.extension(f.path).replaceAll('.', '').toUpperCase();
                    final bytes = f.lengthSync();
                    final size = bytes < 1024 * 1024
                        ? '${(bytes / 1024).toStringAsFixed(1)} KB'
                        : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

                    return GestureDetector(
                      onTap: () {
                        if (sel) widget.selected.remove(f.path);
                        else     widget.selected.add(f.path);
                        widget.onChanged();
                        setState(() {});
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: sel ? _kBlue.withOpacity(0.06) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: sel ? _kBlue.withOpacity(0.3) : const Color(0xFFEEEEEE)),
                        ),
                        child: Row(children: [
                          Container(
                            width: 46, height: 46,
                            decoration: BoxDecoration(
                              color: _kBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10)),
                            child: Center(child: Text(
                              ext.length > 4 ? ext.substring(0, 4) : ext,
                              style: TextStyle(
                                  color: _kBlue, fontSize: 11, fontWeight: FontWeight.w800))),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: _kText, fontSize: 13, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 3),
                            Text(size, style: const TextStyle(color: _kSub, fontSize: 11)),
                          ])),
                          const SizedBox(width: 8),
                          _CircleCheck(selected: sel),
                        ]),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
            left: 20, right: 16, top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
        ),
        child: Row(children: [
          Text('${widget.selected.length} file(s) selected',
              style: const TextStyle(color: _kSub, fontSize: 14)),
          const Spacer(),
          SizedBox(
            width: 120, height: 44,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue, foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: const Text('DONE',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ]),
      ),
    );
  }
}
