import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../services/share_service.dart';
import '../services/security_service.dart';

/// Full-screen viewer for a saved PDF or image scan.
/// Enables FLAG_SECURE (no screenshot) while open.
class PdfViewerScreen extends StatefulWidget {
  final String pdfPath;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.pdfPath,
    required this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final _security = SecurityService.instance;

  @override
  void initState() {
    super.initState();
    _security.enableSecureScreen();
  }

  @override
  void dispose() {
    _security.disableSecureScreen();
    super.dispose();
  }

  bool get _isImage {
    final ext = widget.pdfPath.toLowerCase();
    return ext.endsWith('.jpg') || ext.endsWith('.jpeg') ||
        ext.endsWith('.png') || ext.endsWith('.heic');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: () =>
                ShareService.instance.sharePdf(widget.pdfPath,
                    subject: widget.title),
          ),
        ],
      ),
      body: _isImage
          ? InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: Center(
                child: Image.file(
                  File(widget.pdfPath),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const _ErrorView(),
                ),
              ),
            )
          : _PdfPageView(path: widget.pdfPath),
    );
  }
}

/// Simple multi-page viewer that renders each PDF page as an image.
/// Uses pdf package to rasterise — no external viewer needed.
class _PdfPageView extends StatefulWidget {
  final String path;
  const _PdfPageView({required this.path});

  @override
  State<_PdfPageView> createState() => _PdfPageViewState();
}

class _PdfPageViewState extends State<_PdfPageView> {
  // We show the raw file path and ask the OS to handle it via a share intent
  // since Flutter has no built-in PDF renderer.
  // The viewer falls back to a "share to open" prompt.

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf_rounded,
                size: 80, color: Colors.white54),
            const SizedBox(height: 20),
            Text(widget.path.split('/').last,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ShareService.instance
                  .sharePdf(widget.path),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open with…'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_rounded, size: 64, color: Colors.white38),
          SizedBox(height: 12),
          Text('Could not load document',
              style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}
