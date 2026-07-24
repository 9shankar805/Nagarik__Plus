import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../models/scan_document.dart';
import '../repositories/scanner_repository.dart';
import '../services/share_service.dart';
import '../widgets/biometric_lock_gate.dart';
import 'pdf_viewer_screen.dart';

/// Browse, search, and manage saved scan documents.
/// Gated behind biometric / PIN authentication.
class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BiometricLockGate(
      reason: 'Authenticate to access your Document Vault',
      child: _VaultBody(),
    );
  }
}

class _VaultBody extends StatefulWidget {
  const _VaultBody();
  @override
  State<_VaultBody> createState() => _VaultBodyState();
}

class _VaultBodyState extends State<_VaultBody> {
  final _repo        = ScannerRepository.instance;
  final _searchCtrl  = TextEditingController();
  List<ScanDocument> _all       = [];
  List<ScanDocument> _filtered  = [];
  DocCategory?       _catFilter;
  bool               _loading   = true;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final docs = await _repo.loadAll();
    setState(() {
      _all     = docs;
      _loading = false;
      _applyFilter();
    });
  }

  void _applyFilter() {
    final q   = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filtered = _all.where((d) {
        final matchCat  = _catFilter == null || d.category == _catFilter;
        final matchText = q.isEmpty ||
            d.name.toLowerCase().contains(q) ||
            (d.ocrText?.toLowerCase().contains(q) ?? false) ||
            d.tags.any((t) => t.toLowerCase().contains(q)) ||
            d.category.label.toLowerCase().contains(q);
        return matchCat && matchText;
      }).toList();
    });
  }

  Future<void> _delete(ScanDocument doc) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete document?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Delete "${doc.name}"? This cannot be undone.',
            style: const TextStyle(color: AppColors.textMedium)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok == true) {
      await _repo.deleteDocument(doc.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Document Vault',
            style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name, text, category, tag…',
                prefixIcon:
                    const Icon(Icons.search_rounded, color: AppColors.textLight),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ),

          // ── Category filter chips ────────────────────────────────────────
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              children: [
                _CatChip(
                  label: 'All',
                  active: _catFilter == null,
                  onTap: () => setState(() {
                    _catFilter = null;
                    _applyFilter();
                  }),
                ),
                ...DocCategory.values.map((c) => _CatChip(
                      label: c.label,
                      active: _catFilter == c,
                      onTap: () => setState(() {
                        _catFilter = c;
                        _applyFilter();
                      }),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Document list ────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? _EmptyState()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _DocTile(
                            doc:      _filtered[i],
                            onOpen:   () => _openDoc(_filtered[i]),
                            onShare:  () => _shareDoc(_filtered[i]),
                            onDelete: () => _delete(_filtered[i]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _openDoc(ScanDocument doc) {
    if (doc.savedPdfPath != null) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PdfViewerScreen(
              pdfPath: doc.savedPdfPath!, title: doc.name)));
    } else if (doc.pages.isNotEmpty) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => PdfViewerScreen(
              pdfPath: doc.pages.first.processedPath, title: doc.name)));
    }
  }

  Future<void> _shareDoc(ScanDocument doc) async {
    if (doc.savedPdfPath != null) {
      await ShareService.instance.sharePdf(doc.savedPdfPath!,
          subject: doc.name);
    } else if (doc.pages.isNotEmpty) {
      await ShareService.instance.exportAndSharePages(
          pages: doc.pages, documentName: doc.name);
    }
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────
class _DocTile extends StatelessWidget {
  final ScanDocument doc;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _DocTile({
    required this.doc,
    required this.onOpen,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final thumb = doc.pages.isNotEmpty
        ? doc.pages.first.processedPath
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              Container(
                width: 52,
                height: 68,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.divider),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: thumb != null && File(thumb).existsSync()
                      ? Image.file(File(thumb), fit: BoxFit.cover)
                      : const Icon(Icons.description_outlined,
                          size: 28, color: AppColors.textLight),
                ),
              ),
              const SizedBox(width: 12),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.textDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      _Badge(doc.category.label),
                      const SizedBox(width: 6),
                      _Badge('${doc.pages.length} page${doc.pages.length > 1 ? 's' : ''}',
                          color: AppColors.info),
                    ]),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(doc.createdAt),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textLight),
                    ),
                    if (doc.ocrText != null && doc.ocrText!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          doc.ocrText!.replaceAll('\n', ' '),
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.textLight),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'open')   onOpen();
                  if (v == 'share')  onShare();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'open',
                      child: ListTile(leading: Icon(Icons.open_in_new_rounded),
                          title: Text('Open'))),
                  const PopupMenuItem(value: 'share',
                      child: ListTile(leading: Icon(Icons.share_rounded),
                          title: Text('Share'))),
                  const PopupMenuItem(value: 'delete',
                      child: ListTile(
                          leading: Icon(Icons.delete_rounded,
                              color: AppColors.danger),
                          title: Text('Delete',
                              style:
                                  TextStyle(color: AppColors.danger)))),
                ],
                child: const Icon(Icons.more_vert_rounded,
                    color: AppColors.textLight),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color? color;
  const _Badge(this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 10, color: c, fontWeight: FontWeight.w700)),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _CatChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? AppColors.primary : AppColors.divider),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : AppColors.textMedium,
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open_rounded,
              size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No documents yet',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMedium)),
          const SizedBox(height: 8),
          const Text('Tap the scan button to add your first document.',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textLight)),
        ],
      ),
    );
  }
}
