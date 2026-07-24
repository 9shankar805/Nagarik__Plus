import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/scanner_controller.dart';
import '../models/scan_document.dart';
import '../widgets/corner_adjust_view.dart';
import 'save_sheet.dart';

const _teal = Color(0xFF26A69A);
const _dark = Color(0xFF1A1A1A);
const _darkCard = Color(0xFF242424);

/// CamScanner-style review screen with fully working toolbar.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});
  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int  _filterIndex = 0; // Enhance selected by default
  bool _showCrop    = false;
  bool _showCompare = false; // toggle between original / processed
  String _title     = '';

  static const _filters = [
    _Filter('Enhance',       Icons.auto_fix_high_rounded,       true),
    _Filter('Magic Pro',     Icons.auto_awesome_rounded,        false),
    _Filter('No Watermark',  Icons.format_clear_rounded,        false),
    _Filter('No Shadow',     Icons.wb_shade_rounded,            false),
    _Filter('No Handwriting',Icons.edit_off_rounded,            false),
    _Filter('B&W',           Icons.contrast_rounded,            false),
    _Filter('Gray',          Icons.gradient_rounded,            false),
    _Filter('Color',         Icons.palette_rounded,             false),
  ];

  @override
  void initState() {
    super.initState();
    // Set initial title from formatted date
    _title = 'Nagarik+ Scan ${_formattedDate()}';
  }

  Future<void> _handleDiscard() async {
    final discard = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: _darkCard,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Discard scan?',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800)),
            content: const Text('Unsaved changes will be lost.',
                style: TextStyle(color: Colors.white54)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white54))),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Discard',
                      style: TextStyle(color: AppColors.danger))),
            ],
          ),
        ) ??
        false;
    if (discard && mounted) {
      context.read<ScannerController>().reset();
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleRename() async {
    final ctrl = TextEditingController(text: _title);
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rename Document',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Document name',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white12,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('Rename', style: TextStyle(color: _teal))),
        ],
      ),
    );
    ctrl.dispose();
    if (newName != null && newName.isNotEmpty) {
      setState(() => _title = newName);
    }
  }

  Future<void> _handleExtractText(ScannerController ctrl) async {
    final page = ctrl.selectedPage;
    if (page == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        backgroundColor: _darkCard,
        content: Row(children: [
          CircularProgressIndicator(color: _teal),
          SizedBox(width: 16),
          Text('Extracting text…', style: TextStyle(color: Colors.white)),
        ]),
      ),
    );

    final text = await ctrl.extractTextFromPage(ctrl.selectedPageIndex);
    if (!mounted) return;
    Navigator.of(context).pop(); // close progress

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No text found in this image'),
        backgroundColor: _darkCard,
      ));
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: _darkCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ExtractedTextSheet(text: text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ScannerController>();
    final page = ctrl.selectedPage;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleDiscard();
      },
      child: Scaffold(
        backgroundColor: _dark,
        body: Column(
          children: [
            // ── TOP BAR ────────────────────────────────────────────────────
            SafeArea(
              bottom: false,
              child: _buildTopBar(context, ctrl),
            ),

            // ── PAGE AREA ──────────────────────────────────────────────────
            Expanded(
              child: _showCrop && page != null
                  ? CornerAdjustView(
                      imagePath:       page.processedPath,
                      corners:         ctrl.corners,
                      onCornersChanged: (c) {
                        ctrl.updateCorners(c);
                        ctrl.reapplyCorners();
                      },
                    )
                  : _buildPageArea(ctrl, page),
            ),

            // ── PAGE COUNTER + COMPARE ─────────────────────────────────────
            _buildPageCounter(ctrl),

            // ── FILTER STRIP ───────────────────────────────────────────────
            _buildFilterStrip(ctrl),

            // ── BOTTOM TOOLBAR ─────────────────────────────────────────────
            SafeArea(
              top: false,
              child: _buildBottomToolbar(context, ctrl),
            ),
          ],
        ),
      ),
    );
  }

  // ── TOP BAR ────────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, ScannerController ctrl) {
    return Container(
      color: _dark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // ← back
          GestureDetector(
            onTap: _handleDiscard,
            child: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),

          // Title (tappable to rename)
          Expanded(
            child: GestureDetector(
              onTap: _handleRename,
              child: Container(
                padding: const EdgeInsets.only(bottom: 2),
                decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: Colors.white30,
                          width: 1,
                          style: BorderStyle.solid)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _title.isEmpty ? 'New Scan' : _title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.edit_rounded,
                        color: Colors.white54, size: 16),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Add (teal) — go back to camera to capture more pages
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Text('Add',
                style: TextStyle(
                    color: _teal,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  String _formattedDate() {
    final now = DateTime.now();
    return '${now.day}-${now.month}-${now.year} '
        '${now.hour.toString().padLeft(2, '0')}.'
        '${now.minute.toString().padLeft(2, '0')}';
  }

  // ── PAGE AREA ─────────────────────────────────────────────────────────────
  Widget _buildPageArea(ScannerController ctrl, ScanPage? page) {
    return Container(
      color: _dark,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: page == null
          // Empty state — dashed border + Add Page button
          ? _buildEmptyPage(ctrl)
          : Stack(
              children: [
                // Image fills the area — compare toggle shows original
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                        color: Colors.white12, width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: InteractiveViewer(
                      minScale: 0.8,
                      maxScale: 4.0,
                      child: SizedBox(
                        width: double.infinity,
                        child: Image.file(
                          File(_showCompare
                              ? page.originalPath
                              : page.processedPath),
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const _BrokenImage(),
                        ),
                      ),
                    ),
                  ),
                ),

                // "ORIGINAL" label when comparing
                if (_showCompare)
                  Positioned(
                    top: 8, left: 0, right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text('ORIGINAL',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2)),
                      ),
                    ),
                  ),

                // Delete icon top-left
                Positioned(
                  top: 8, left: 8,
                  child: GestureDetector(
                    onTap: () => _confirmDelete(ctrl),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.delete_rounded,
                          color: Colors.white70, size: 18),
                    ),
                  ),
                ),

                // Processing overlay
                if (ctrl.isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                        child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: _teal),
                        SizedBox(height: 12),
                        Text('Processing…',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 13)),
                      ],
                    )),
                  ),
              ],
            ),
    );
  }

  Future<void> _confirmDelete(ScannerController ctrl) async {
    if (ctrl.pages.length == 1) {
      // Only one page — discard the whole session
      _handleDiscard();
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete page?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: const Text('This page will be removed.',
            style: TextStyle(color: Colors.white54)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok == true) ctrl.deletePage(ctrl.selectedPageIndex);
  }

  // Empty page placeholder with dashed border
  Widget _buildEmptyPage(ScannerController ctrl) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: CustomPaint(
        painter: _DashedBorderPainter(),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_a_photo_rounded,
                  color: _teal, size: 48),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: _teal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Add Page',
                    style: TextStyle(
                        color: _teal,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── PAGE COUNTER ──────────────────────────────────────────────────────────
  Widget _buildPageCounter(ScannerController ctrl) {
    final total = ctrl.pages.length;
    final cur   = ctrl.selectedPageIndex + 1;

    return Container(
      color: _dark,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ◄ prev
          GestureDetector(
            onTap: cur > 1
                ? () => ctrl.selectPage(ctrl.selectedPageIndex - 1)
                : null,
            child: Icon(Icons.navigate_before_rounded,
                color: cur > 1 ? Colors.white : Colors.white24,
                size: 26),
          ),
          const SizedBox(width: 16),
          Text(
            total == 0 ? '0/0' : '$cur/$total',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 16),
          // ► next
          GestureDetector(
            onTap: cur < total
                ? () => ctrl.selectPage(ctrl.selectedPageIndex + 1)
                : null,
            child: Icon(Icons.navigate_next_rounded,
                color: cur < total ? Colors.white : Colors.white24,
                size: 26),
          ),
          const Spacer(),
          // Compare button (right side) — toggle original/processed
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => setState(() => _showCompare = !_showCompare),
              child: Row(
                children: [
                  Icon(Icons.compare_rounded,
                      color: _showCompare ? _teal : Colors.white60,
                      size: 18),
                  const SizedBox(width: 4),
                  Text('Compare',
                      style: TextStyle(
                          color: _showCompare ? _teal : Colors.white60,
                          fontSize: 12,
                          fontWeight: _showCompare
                              ? FontWeight.w700
                              : FontWeight.w400)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── FILTER STRIP ──────────────────────────────────────────────────────────
  Widget _buildFilterStrip(ScannerController ctrl) {
    return Container(
      color: _dark,
      height: 86,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _filters.length,
        itemBuilder: (_, i) {
          final f      = _filters[i];
          final active = i == _filterIndex;
          return GestureDetector(
            onTap: () {
              setState(() => _filterIndex = i);
              final sf = _mapFilter(i);
              ctrl.applyFilter(sf);
            },
            child: Container(
              width: 72,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: active
                    ? _teal.withValues(alpha: 0.18)
                    : _darkCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active ? _teal : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(f.icon,
                      size: 22,
                      color: active ? _teal : Colors.white38),
                  const SizedBox(height: 4),
                  Text(f.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 9,
                          color: active ? _teal : Colors.white38,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w400),
                      maxLines: 2),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  ScanFilter _mapFilter(int i) {
    const map = [
      ScanFilter.auto,         // Enhance
      ScanFilter.magicColor,   // Magic Pro
      ScanFilter.cleanPaper,   // No Watermark
      ScanFilter.document,     // No Shadow
      ScanFilter.gray,         // No Handwriting
      ScanFilter.blackAndWhite,
      ScanFilter.gray,
      ScanFilter.color,
    ];
    return i < map.length ? map[i] : ScanFilter.auto;
  }

  // ── BOTTOM TOOLBAR ────────────────────────────────────────────────────────
  Widget _buildBottomToolbar(BuildContext context, ScannerController ctrl) {
    return Container(
      color: _dark,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Retake
          _ToolBtn(
            icon:  Icons.camera_alt_outlined,
            label: 'Retake',
            onTap: () => Navigator.of(context).pop(),
          ),
          // Left (rotate CCW)
          _ToolBtn(
            icon:  Icons.rotate_left_rounded,
            label: 'Left',
            onTap: ctrl.isProcessing
                ? null
                : () => ctrl.rotatePage(
                    ctrl.selectedPageIndex, clockwise: false),
          ),
          // Crop
          _ToolBtn(
            icon:  Icons.crop_rounded,
            label: 'Crop',
            onTap: () => setState(() => _showCrop = !_showCrop),
            active: _showCrop,
          ),
          // Extract Text
          _ToolBtn(
            icon:  Icons.text_fields_rounded,
            label: 'Extract',
            onTap: ctrl.isProcessing
                ? null
                : () => _handleExtractText(ctrl),
          ),
          // Rename
          _ToolBtn(
            icon:  Icons.drive_file_rename_outline_rounded,
            label: 'Rename',
            onTap: _handleRename,
          ),

          const Spacer(),
          // ✓ Confirm — open save sheet
          GestureDetector(
            onTap: () => _openSaveSheet(context, ctrl),
            child: Container(
              width: 54,
              height: 44,
              decoration: BoxDecoration(
                color: _teal,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 26),
            ),
          ),
        ],
      ),
    );
  }

  void _openSaveSheet(BuildContext context, ScannerController ctrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: ctrl,
        child: const SaveSheet(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Extracted text bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _ExtractedTextSheet extends StatelessWidget {
  final String text;
  const _ExtractedTextSheet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Extracted Text',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.copy_rounded, color: Colors.white70),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Copied to clipboard'),
                ));
              },
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white70),
              onPressed: () => Navigator.pop(context),
            ),
          ]),
          const SizedBox(height: 12),
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              child: Text(
                text,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.87), fontSize: 13, height: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Filter {
  final String label;
  final IconData icon;
  final bool isFree;
  const _Filter(this.label, this.icon, this.isFree);
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;
  const _ToolBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = onTap == null
        ? Colors.white24
        : active
            ? _teal
            : Colors.white70;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 3),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _BrokenImage extends StatelessWidget {
  const _BrokenImage();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.broken_image_rounded,
          size: 64, color: Colors.white24),
    );
  }
}

/// Paints a dashed border around the widget.
class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashW  = 8.0;
    const gapW   = 6.0;
    const radius = 4.0;
    final paint  = Paint()
      ..color       = Colors.white30
      ..strokeWidth = 1.5
      ..style       = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect =
        RRect.fromRectAndRadius(rect, const Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final metric = path.computeMetrics().first;
    double dist = 0;
    while (dist < metric.length) {
      final end = (dist + dashW).clamp(0, metric.length);
      canvas.drawPath(
          metric.extractPath(dist, end.toDouble()), paint);
      dist += dashW + gapW;
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter _) => false;
}
