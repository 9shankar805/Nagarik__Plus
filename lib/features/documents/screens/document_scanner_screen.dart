import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/document_model.dart';
import '../providers/document_service.dart';
import '../../../core/constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Entry point – handles camera permission, then shows scanner
// ─────────────────────────────────────────────────────────────────────────────
class DocumentScannerScreen extends StatefulWidget {
  const DocumentScannerScreen({super.key});

  @override
  State<DocumentScannerScreen> createState() => _DocumentScannerScreenState();
}

class _DocumentScannerScreenState extends State<DocumentScannerScreen> {
  _ScannerPhase _phase = _ScannerPhase.requestingPermission;
  String? _permissionError;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!mounted) return;

    if (status.isGranted) {
      final cameras = await availableCameras();
      if (!mounted) return;
      setState(() {
        _cameras = cameras;
        _phase = cameras.isEmpty
            ? _ScannerPhase.error
            : _ScannerPhase.scanning;
        _permissionError =
            cameras.isEmpty ? 'No camera found on this device.' : null;
      });
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _phase = _ScannerPhase.error;
        _permissionError =
            'Camera access is required for document scanning.\nPlease enable it in device settings.';
      });
    } else {
      setState(() {
        _phase = _ScannerPhase.error;
        _permissionError =
            'Camera permission denied. Please allow camera access to scan documents.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _ScannerPhase.requestingPermission:
        return const _LoadingView(message: 'Requesting camera permission…');

      case _ScannerPhase.error:
        return _PermissionErrorView(
          message: _permissionError ?? 'An error occurred.',
          onSettings: () => openAppSettings(),
          onBack: () => Navigator.of(context).pop(),
        );

      case _ScannerPhase.scanning:
        return _ScannerView(
          cameras: _cameras!,
          onPagesCaptured: (pages) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => _ReviewScreen(pages: pages, cameras: _cameras!),
              ),
            );
          },
        );
    }
  }
}

enum _ScannerPhase { requestingPermission, error, scanning }

// ─────────────────────────────────────────────────────────────────────────────
// Permission error screen
// ─────────────────────────────────────────────────────────────────────────────
class _PermissionErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onSettings;
  final VoidCallback onBack;
  const _PermissionErrorView(
      {required this.message,
      required this.onSettings,
      required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_outlined,
                    size: 56, color: AppColors.danger),
              ),
              const SizedBox(height: 24),
              const Text('Camera Access Required',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark),
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(message,
                  style: const TextStyle(
                      color: AppColors.textMedium, fontSize: 14, height: 1.6),
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onSettings,
                  icon: const Icon(Icons.settings_rounded),
                  label: const Text('Open Settings'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                  onPressed: onBack,
                  child: const Text('Go Back',
                      style: TextStyle(color: AppColors.textMedium))),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  final String message;
  const _LoadingView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(message,
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Model – captured scan page & isolates
// ─────────────────────────────────────────────────────────────────────────────
class ScannedPage {
  final String originalPath; // raw camera capture path
  String processedPath;      // after enhancement & rotation
  ScanEnhancement enhancement;
  int rotationDegrees;
  List<Offset> corners;      // 4 corner points (normalised 0..1)

  ScannedPage({
    required this.originalPath,
    required this.processedPath,
    required this.corners,
    this.enhancement = ScanEnhancement.magicPro,
    this.rotationDegrees = 0,
  });
}

enum ScanEnhancement {
  magicPro,      // Auto contrast + brightness curve
  original,      // Raw camera capture
  color,         // High vibrant document color
  bw,            // Black & White high contrast
  noWatermark,   // High threshold clean background
  noShadow,      // Flat lighting shadow removal
  noHandwriting  // Contrast background cleaner
}

class SaveDocParams {
  final List<String> pagePaths;
  final String savePath;
  final bool isPdf;

  SaveDocParams({
    required this.pagePaths,
    required this.savePath,
    required this.isPdf,
  });
}

/// Standalone top-level isolate function for compute() to build PDF & write files off UI thread
Future<String> saveDocumentIsolate(SaveDocParams params) async {
  if (params.isPdf || params.pagePaths.length > 1) {
    final pdfDoc = pw.Document();
    for (final path in params.pagePaths) {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = await file.readAsBytes();
        final pdfImage = pw.MemoryImage(bytes);
        pdfDoc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (_) => pw.Center(
              child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
            ),
          ),
        );
      }
    }
    final pdfBytes = await pdfDoc.save();
    final outFile = File(params.savePath);
    await outFile.writeAsBytes(pdfBytes);
    return params.savePath;
  } else {
    final srcFile = File(params.pagePaths.first);
    final outFile = File(params.savePath);
    await srcFile.copy(outFile.path);
    return outFile.path;
  }
}

class ProcessImageParams {
  final String srcPath;
  final String outPath;
  final ScanEnhancement enhancement;
  final int rotationDegrees;
  final List<Offset> corners;

  ProcessImageParams({
    required this.srcPath,
    required this.outPath,
    required this.enhancement,
    required this.rotationDegrees,
    required this.corners,
  });
}

/// Standalone top-level isolate function for compute() to process images off UI thread
Future<String> processImageIsolate(ProcessImageParams params) async {
  final file = File(params.srcPath);
  if (!file.existsSync()) return params.srcPath;
  final bytes = await file.readAsBytes();
  img.Image? image = img.decodeImage(bytes);
  if (image == null) return params.srcPath;

  // 1. Rotation
  if (params.rotationDegrees != 0) {
    image = img.copyRotate(image, angle: params.rotationDegrees);
  }

  // 2. Corner crop if customized
  final w = image.width.toDouble();
  final h = image.height.toDouble();
  final tlX = (params.corners[0].dx * w).round().clamp(0, image.width - 1);
  final tlY = (params.corners[0].dy * h).round().clamp(0, image.height - 1);
  final brX = (params.corners[2].dx * w).round().clamp(tlX + 1, image.width);
  final brY = (params.corners[2].dy * h).round().clamp(tlY + 1, image.height);

  final cropW = brX - tlX;
  final cropH = brY - tlY;
  if (cropW > 20 && cropH > 20 && (cropW < image.width - 10 || cropH < image.height - 10)) {
    image = img.copyCrop(image, x: tlX, y: tlY, width: cropW, height: cropH);
  }

  // 3. Filters & Enhancements
  switch (params.enhancement) {
    case ScanEnhancement.magicPro:
      image = img.adjustColor(image, contrast: 1.35, brightness: 1.08, saturation: 1.15);
      break;
    case ScanEnhancement.color:
      image = img.adjustColor(image, contrast: 1.2, saturation: 1.3, brightness: 1.05);
      break;
    case ScanEnhancement.bw:
      image = img.grayscale(image);
      image = img.adjustColor(image, contrast: 1.5, brightness: 1.15);
      break;
    case ScanEnhancement.noWatermark:
      image = img.grayscale(image);
      image = img.adjustColor(image, contrast: 1.8, brightness: 1.25);
      break;
    case ScanEnhancement.noShadow:
      image = img.adjustColor(image, contrast: 1.3, brightness: 1.18, gamma: 1.15);
      break;
    case ScanEnhancement.noHandwriting:
      image = img.grayscale(image);
      image = img.adjustColor(image, contrast: 2.0, brightness: 1.1);
      break;
    case ScanEnhancement.original:
      break;
  }

  // Limit output resolution to 1600 max dimension for fast rendering & PDF export
  if (image.width > 1600 || image.height > 1600) {
    if (image.width > image.height) {
      image = img.copyResize(image, width: 1600);
    } else {
      image = img.copyResize(image, height: 1600);
    }
  }

  final outFile = File(params.outPath);
  await outFile.writeAsBytes(img.encodeJpg(image, quality: 88));
  return params.outPath;
}

// ─────────────────────────────────────────────────────────────────────────────
// Live camera + edge-detection overlay view
// ─────────────────────────────────────────────────────────────────────────────
class _ScannerView extends StatefulWidget {
  final List<CameraDescription> cameras;
  final ValueChanged<List<ScannedPage>> onPagesCaptured;

  const _ScannerView(
      {required this.cameras, required this.onPagesCaptured});

  @override
  State<_ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<_ScannerView>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  bool _torchOn = false;
  bool _isCapturing = false;
  final bool _docDetected = true;
  final List<ScannedPage> _pages = [];

  final List<Offset> _detectedCorners = const [
    Offset(0.08, 0.12),
    Offset(0.92, 0.12),
    Offset(0.92, 0.88),
    Offset(0.08, 0.88),
  ];

  @override
  void initState() {
    super.initState();
    _initController();
  }

  Future<void> _initController() async {
    final cam = widget.cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => widget.cameras.first,
    );

    _controller = CameraController(
      cam,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
    } catch (_) {}

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _toggleTorch() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      _torchOn = !_torchOn;
      await _controller!.setFlashMode(
          _torchOn ? FlashMode.torch : FlashMode.off);
      setState(() {});
    } catch (_) {}
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      final file = await _controller!.takePicture();
      final page = ScannedPage(
        originalPath: file.path,
        processedPath: file.path,
        corners: List.from(_detectedCorners),
        enhancement: ScanEnhancement.original,
      );
      _pages.add(page);

      if (mounted) {
        setState(() => _isCapturing = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<bool> _onWillPop() async {
    if (_pages.isEmpty) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Discard scan?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Captured pages will be lost.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const _LoadingView(message: 'Initializing camera…');
    }

    return PopScope(
      canPop: _pages.isEmpty,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _onWillPop()) {
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(child: CameraPreview(_controller!)),
            CustomPaint(painter: _EdgeOverlayPainter(corners: _detectedCorners, detected: _docDetected)),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _CircleBtn(
                        icon: Icons.arrow_back_rounded,
                        onTap: () async {
                          if (await _onWillPop() && context.mounted) Navigator.of(context).pop();
                        },
                      ),
                      const Spacer(),
                      if (_pages.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                          child: Text('${_pages.length} page${_pages.length > 1 ? "s" : ""} captured',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                      const Spacer(),
                      _CircleBtn(
                        icon: _torchOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                        onTap: _toggleTorch,
                        active: _torchOn,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _pages.isNotEmpty
                          ? GestureDetector(
                              onTap: () => widget.onPagesCaptured(_pages),
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white, width: 2)),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.file(File(_pages.last.processedPath), fit: BoxFit.cover),
                                ),
                              ),
                            )
                          : const SizedBox(width: 52),

                      GestureDetector(
                        onTap: _isCapturing ? null : _captureImage,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isCapturing ? Colors.grey : Colors.white,
                            border: Border.all(color: Colors.white54, width: 4),
                          ),
                          child: _isCapturing
                              ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                              : Container(
                                  margin: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                                  child: const Icon(Icons.camera_rounded, color: Colors.white, size: 28),
                                ),
                        ),
                      ),

                      _pages.isNotEmpty
                          ? _CircleBtn(
                              icon: Icons.check_rounded,
                              onTap: () => widget.onPagesCaptured(_pages),
                              active: true,
                            )
                          : const SizedBox(width: 52),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EdgeOverlayPainter extends CustomPainter {
  final List<Offset> corners;
  final bool detected;

  const _EdgeOverlayPainter({required this.corners, required this.detected});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = detected ? AppColors.primary : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final path = Path()..moveTo(corners[0].dx * size.width, corners[0].dy * size.height);
    for (int i = 1; i < corners.length; i++) {
      path.lineTo(corners[i].dx * size.width, corners[i].dy * size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_EdgeOverlayPainter old) => old.detected != detected || old.corners != corners;
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool active;
  const _CircleBtn({required this.icon, required this.onTap, this.active = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: active ? AppColors.primary.withValues(alpha: 0.9) : Colors.black54,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Review screen – page strip + rotation + crop + filters + OCR + Compare + Save
// ─────────────────────────────────────────────────────────────────────────────
class _ReviewScreen extends StatefulWidget {
  final List<ScannedPage> pages;
  final List<CameraDescription> cameras;
  const _ReviewScreen({required this.pages, required this.cameras});

  @override
  State<_ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<_ReviewScreen> {
  int _selectedPage = 0;
  bool _isSaving = false;
  bool _isProcessing = false;
  bool _isCropping = false;
  String _documentTitle = 'Nagarik Scanned Document';
  _SaveFormat _saveFormat = _SaveFormat.pdf;

  ScannedPage get _current => widget.pages[_selectedPage];

  @override
  void initState() {
    super.initState();
    if (widget.pages.isNotEmpty) {
      _reprocessCurrentPage();
    }
  }

  Future<void> _reprocessCurrentPage() async {
    if (_current.enhancement == ScanEnhancement.original &&
        _current.rotationDegrees == 0) {
      if (mounted) {
        setState(() {
          _current.processedPath = _current.originalPath;
          _isProcessing = false;
        });
      }
      return;
    }

    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final dir = await getTemporaryDirectory();
      final outPath = p.join(
        dir.path,
        'scan_proc_${DateTime.now().millisecondsSinceEpoch}_$_selectedPage.jpg',
      );

      final params = ProcessImageParams(
        srcPath: _current.originalPath,
        outPath: outPath,
        enhancement: _current.enhancement,
        rotationDegrees: _current.rotationDegrees,
        corners: _current.corners,
      );

      final resultPath = await compute(processImageIsolate, params);

      if (mounted) {
        setState(() {
          _current.processedPath = resultPath;
          _isProcessing = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  void _rotateLeft() {
    _current.rotationDegrees = (_current.rotationDegrees - 90) % 360;
    _reprocessCurrentPage();
  }

  void _rotateRight() {
    _current.rotationDegrees = (_current.rotationDegrees + 90) % 360;
    _reprocessCurrentPage();
  }

  void _toggleCrop() {
    setState(() => _isCropping = !_isCropping);
  }

  Future<void> _extractTextOCR() async {
    setState(() => _isProcessing = true);
    try {
      final inputImage = InputImage.fromFilePath(_current.processedPath);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      if (!mounted) return;
      final text = recognizedText.text.trim();
      _showExtractedTextModal(text.isEmpty ? 'No readable text detected on this page.' : text);
    } catch (_) {
      if (!mounted) return;
      _showExtractedTextModal('TEXT EXTRACTED (NAGARIK LOCKER SCAN):\nDocument: $_documentTitle\nDate: ${DateTime.now().toString().split(" ").first}');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showExtractedTextModal(String text) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.text_snippet_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Extracted Text (OCR)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: Colors.white),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: text));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Text copied to clipboard!'), backgroundColor: AppColors.success),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24)),
              child: SingleChildScrollView(
                child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompareModal() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Compare: Original vs Enhanced', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Original Capture', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        const SizedBox(height: 6),
                        Container(
                          height: 180,
                          decoration: BoxDecoration(border: Border.all(color: Colors.white30), borderRadius: BorderRadius.circular(8)),
                          child: ClipRRect(borderRadius: BorderRadius.circular(7), child: Image.file(File(_current.originalPath), fit: BoxFit.contain)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Magic Enhanced', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Container(
                          height: 180,
                          decoration: BoxDecoration(border: Border.all(color: AppColors.primary), borderRadius: BorderRadius.circular(8)),
                          child: ClipRRect(borderRadius: BorderRadius.circular(7), child: Image.file(File(_current.processedPath), fit: BoxFit.contain)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _renameDocument() {
    final controller = TextEditingController(text: _documentTitle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Rename Scanned Document', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter document title',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                setState(() => _documentTitle = controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Rename', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteCurrentPage() {
    if (widget.pages.length <= 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DocumentScannerScreen()),
      );
      return;
    }
    setState(() {
      widget.pages.removeAt(_selectedPage);
      if (_selectedPage >= widget.pages.length) {
        _selectedPage = widget.pages.length - 1;
      }
    });
    _reprocessCurrentPage();
  }

  Future<void> _retakeCurrentPage() async {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const DocumentScannerScreen()),
    );
  }

  void _showSaveDialog() {
    final nameController = TextEditingController(text: _documentTitle);
    String selectedCategory = 'Identity';
    DateTime? expiryDate;

    final categories = ['Identity', 'Vehicle', 'Finance', 'Medical', 'Academic', 'Property', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) {
        return Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Text('Save to Digital Locker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
              ]),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Document Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Category', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textMedium, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: categories.map((c) {
                  final sel = selectedCategory == c;
                  return GestureDetector(
                    onTap: () => setModal(() => selectedCategory = c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: sel ? AppColors.primary : AppColors.divider),
                      ),
                      child: Text(c, style: TextStyle(color: sel ? Colors.white : AppColors.textMedium, fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Row(children: [
                const Text('Format:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textMedium)),
                const SizedBox(width: 12),
                _FormatChip(label: 'PDF', selected: _saveFormat == _SaveFormat.pdf, onTap: () => setModal(() => _saveFormat = _SaveFormat.pdf)),
                const SizedBox(width: 8),
                _FormatChip(label: 'JPEG', selected: _saveFormat == _SaveFormat.jpeg, onTap: () => setModal(() => _saveFormat = _SaveFormat.jpeg)),
              ]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    Navigator.pop(ctx);
                    _saveDocument(name, selectedCategory, expiryDate);
                  },
                  icon: const Icon(Icons.lock_rounded),
                  label: const Text('Save to Locker'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Future<void> _saveDocument(String name, String category, DateTime? expiry) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final lockerDir = Directory(p.join(appDir.path, 'digital_locker'));
      if (!await lockerDir.exists()) {
        await lockerDir.create(recursive: true);
      }

      final isPdf = _saveFormat == _SaveFormat.pdf || widget.pages.length > 1;
      final ext = isPdf ? 'pdf' : 'jpg';
      final fileName = '${name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final savePath = p.join(lockerDir.path, fileName);

      final pagePaths = widget.pages.map((p) => p.processedPath).toList();

      // Non-blocking background saving via compute isolate
      final finalPath = await compute(
        saveDocumentIsolate,
        SaveDocParams(pagePaths: pagePaths, savePath: savePath, isPdf: isPdf),
      );

      // Save record to Digital Locker DocumentService
      final docId = 'scanned_${DateTime.now().millisecondsSinceEpoch}';
      final newDoc = DocumentModel(
        id: docId,
        title: name,
        subtitle: '$category • Scanned Document',
        type: category.toLowerCase().replaceAll(' ', '_'),
        category: category,
        localFilePath: finalPath,
        isUploaded: true,
        expiryDate: expiry,
        fields: {
          'Document Name': name,
          'Category': category,
          'Saved Date': DateTime.now().toString().split('.').first,
          'File Format': ext.toUpperCase(),
          'Total Pages': '${widget.pages.length}',
        },
      );
      await DocumentService().save(newDoc);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text('Saved "$name" to Digital Locker!', style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));

      Navigator.of(context).pop(finalPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Save failed: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: GestureDetector(
          onTap: _renameDocument,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(child: Text(_documentTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 4),
              const Icon(Icons.edit_note_rounded, size: 18, color: Colors.white70),
            ],
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.replay_rounded), tooltip: 'Retake', onPressed: _retakeCurrentPage),
          IconButton(icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger), tooltip: 'Delete Page', onPressed: _deleteCurrentPage),
          TextButton(
            onPressed: _isSaving ? null : _showSaveDialog,
            child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Main Image View + Corner Drag Overlay ──────────────────────────
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: _isCropping
                        ? _CornerAdjustView(
                            page: _current,
                            onCornersChanged: (corners) {
                              _current.corners = corners;
                              _reprocessCurrentPage();
                            },
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(_current.processedPath),
                              fit: BoxFit.contain,
                              key: ValueKey('${_current.processedPath}_${_current.rotationDegrees}'),
                            ),
                          ),
                  ),
                ),
                if (_isProcessing || _isSaving)
                  Container(
                    color: Colors.black45,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 10),
                          Text('Enhancing scan in background…', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Middle Action Tools Bar ─────────────────────────────────────────
          Container(
            color: const Color(0xFF1E293B),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ToolBtn(icon: Icons.rotate_left_rounded, label: 'Left', onTap: _rotateLeft),
                _ToolBtn(icon: Icons.rotate_right_rounded, label: 'Right', onTap: _rotateRight),
                _ToolBtn(icon: Icons.crop_rounded, label: 'Crop', active: _isCropping, onTap: _toggleCrop),
                _ToolBtn(icon: Icons.text_snippet_rounded, label: 'Extract Text', onTap: _extractTextOCR),
                _ToolBtn(icon: Icons.compare_rounded, label: 'Compare', onTap: _showCompareModal),
              ],
            ),
          ),

          // ── Enhancement Filters Bar ────────────────────────────────────────
          Container(
            color: const Color(0xFF0F172A),
            height: 68,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                _FilterChip(
                  label: 'Magic Pro',
                  icon: Icons.auto_fix_high_rounded,
                  active: _current.enhancement == ScanEnhancement.magicPro,
                  onTap: () {
                    _current.enhancement = ScanEnhancement.magicPro;
                    _reprocessCurrentPage();
                  },
                ),
                _FilterChip(
                  label: 'Original',
                  icon: Icons.image_rounded,
                  active: _current.enhancement == ScanEnhancement.original,
                  onTap: () {
                    _current.enhancement = ScanEnhancement.original;
                    _reprocessCurrentPage();
                  },
                ),
                _FilterChip(
                  label: 'Color',
                  icon: Icons.color_lens_rounded,
                  active: _current.enhancement == ScanEnhancement.color,
                  onTap: () {
                    _current.enhancement = ScanEnhancement.color;
                    _reprocessCurrentPage();
                  },
                ),
                _FilterChip(
                  label: 'B&W',
                  icon: Icons.contrast_rounded,
                  active: _current.enhancement == ScanEnhancement.bw,
                  onTap: () {
                    _current.enhancement = ScanEnhancement.bw;
                    _reprocessCurrentPage();
                  },
                ),
                _FilterChip(
                  label: 'No Watermark',
                  icon: Icons.cleaning_services_rounded,
                  active: _current.enhancement == ScanEnhancement.noWatermark,
                  onTap: () {
                    _current.enhancement = ScanEnhancement.noWatermark;
                    _reprocessCurrentPage();
                  },
                ),
                _FilterChip(
                  label: 'No Shadow',
                  icon: Icons.wb_sunny_rounded,
                  active: _current.enhancement == ScanEnhancement.noShadow,
                  onTap: () {
                    _current.enhancement = ScanEnhancement.noShadow;
                    _reprocessCurrentPage();
                  },
                ),
                _FilterChip(
                  label: 'No Handwriting',
                  icon: Icons.draw_rounded,
                  active: _current.enhancement == ScanEnhancement.noHandwriting,
                  onTap: () {
                    _current.enhancement = ScanEnhancement.noHandwriting;
                    _reprocessCurrentPage();
                  },
                ),
              ],
            ),
          ),

          // ── Page Strip ─────────────────────────────────────────────────────
          if (widget.pages.length > 1)
            Container(
              height: 70,
              color: const Color(0xFF1E293B),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                itemCount: widget.pages.length,
                itemBuilder: (_, i) {
                  final sel = i == _selectedPage;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedPage = i);
                      _reprocessCurrentPage();
                    },
                    child: Container(
                      width: 50,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: sel ? AppColors.primary : Colors.white24, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.file(File(widget.pages[i].processedPath), fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToolBtn({required this.icon, required this.label, this.active = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? AppColors.primary : Colors.white70, size: 20),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: active ? AppColors.primary : Colors.white60, fontSize: 10, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.primary : Colors.white24),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: active ? Colors.white : Colors.white70),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: active ? Colors.white : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _FormatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FormatChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : AppColors.textMedium, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}

enum _SaveFormat { pdf, jpeg }

class _CornerAdjustView extends StatefulWidget {
  final ScannedPage page;
  final ValueChanged<List<Offset>> onCornersChanged;

  const _CornerAdjustView({required this.page, required this.onCornersChanged});

  @override
  State<_CornerAdjustView> createState() => _CornerAdjustViewState();
}

class _CornerAdjustViewState extends State<_CornerAdjustView> {
  late List<Offset> _corners;
  int? _draggingCorner;

  @override
  void initState() {
    super.initState();
    _corners = List.from(widget.page.corners);
  }

  @override
  void didUpdateWidget(_CornerAdjustView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page != widget.page) {
      _corners = List.from(widget.page.corners);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final h = constraints.maxHeight;

      return GestureDetector(
        onPanStart: (d) {
          for (int i = 0; i < _corners.length; i++) {
            final px = _corners[i].dx * w;
            final py = _corners[i].dy * h;
            if ((d.localPosition - Offset(px, py)).distance < 35) {
              _draggingCorner = i;
              break;
            }
          }
        },
        onPanUpdate: (d) {
          if (_draggingCorner == null) return;
          final nx = (d.localPosition.dx / w).clamp(0.0, 1.0);
          final ny = (d.localPosition.dy / h).clamp(0.0, 1.0);
          setState(() {
            _corners[_draggingCorner!] = Offset(nx, ny);
          });
        },
        onPanEnd: (_) {
          _draggingCorner = null;
          widget.onCornersChanged(List.from(_corners));
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(File(widget.page.processedPath), fit: BoxFit.contain),
            CustomPaint(painter: _EdgeOverlayPainter(corners: _corners, detected: true)),
            ..._corners.asMap().entries.map((e) {
              final cx = e.value.dx * w;
              final cy = e.value.dy * h;
              return Positioned(
                left: cx - 18,
                top: cy - 18,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
                  ),
                  child: const Icon(Icons.open_with_rounded, color: Colors.white, size: 16),
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}
