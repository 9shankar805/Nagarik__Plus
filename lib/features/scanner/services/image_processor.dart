import 'dart:io';
import 'dart:isolate';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/scan_document.dart';

/// Runs heavy image work in an Isolate so the UI thread stays smooth.
/// The temp-directory path is resolved on the main isolate and passed
/// in, because platform plugins are not available in spawned isolates.
class ImageProcessor {
  ImageProcessor._();
  static final ImageProcessor instance = ImageProcessor._();

  // ── Public API ────────────────────────────────────────────────────────────

  Future<String> process({
    required String srcPath,
    required DocumentCorners corners,
    required ScanFilter filter,
    double brightness = 0.0,
    double contrast   = 1.0,
    double saturation = 1.0,
    int rotationDeg   = 0,
    bool flipH        = false,
  }) async {
    // Resolve temp dir on main isolate BEFORE spawning
    final tmpDir = (await getTemporaryDirectory()).path;

    final args = _ProcessArgs(
      srcPath:    srcPath,
      tmpDir:     tmpDir,
      corners:    corners,
      filter:     filter,
      brightness: brightness,
      contrast:   contrast,
      saturation: saturation,
      rotationDeg: rotationDeg,
      flipH:      flipH,
    );

    return await Isolate.run(() => _processInIsolate(args));
  }

  Future<String> compress(String srcPath, {int quality = 80}) async {
    final tmpDir = (await getTemporaryDirectory()).path;
    return await Isolate.run(() => _compressInIsolate(srcPath, tmpDir, quality));
  }

  /// Like [process] but SKIPS perspective crop — for images that are already
  /// cropped by a native scanner (e.g. cunning_document_scanner).
  Future<String> enhanceOnly({
    required String srcPath,
    ScanFilter filter = ScanFilter.auto,
    double brightness = 0.0,
    double contrast   = 1.0,
    double saturation = 1.0,
    int rotationDeg   = 0,
    bool flipH        = false,
  }) async {
    final tmpDir = (await getTemporaryDirectory()).path;
    final args = _ProcessArgs(
      srcPath:     srcPath,
      tmpDir:      tmpDir,
      // Full frame corners → _perspectiveCrop becomes a no-op (0..1 range)
      corners:     DocumentCorners.noOp,
      filter:      filter,
      brightness:  brightness,
      contrast:    contrast,
      saturation:  saturation,
      rotationDeg: rotationDeg,
      flipH:       flipH,
    );
    return await Isolate.run(() => _processInIsolate(args));
  }
}

// ── Isolate payload ───────────────────────────────────────────────────────────
class _ProcessArgs {
  final String srcPath;
  final String tmpDir;
  final DocumentCorners corners;
  final ScanFilter filter;
  final double brightness;
  final double contrast;
  final double saturation;
  final int rotationDeg;
  final bool flipH;

  _ProcessArgs({
    required this.srcPath,
    required this.tmpDir,
    required this.corners,
    required this.filter,
    required this.brightness,
    required this.contrast,
    required this.saturation,
    required this.rotationDeg,
    required this.flipH,
  });
}

// ── Processing in Isolate ─────────────────────────────────────────────────────
Future<String> _processInIsolate(_ProcessArgs a) async {
  final bytes = await File(a.srcPath).readAsBytes();
  img.Image? image = img.decodeImage(bytes);
  if (image == null) return a.srcPath;

  // 1. Perspective crop
  image = _perspectiveCrop(image, a.corners);

  // 2. Rotation
  if (a.rotationDeg != 0) {
    image = img.copyRotate(image, angle: a.rotationDeg.toDouble());
  }

  // 3. Flip
  if (a.flipH) image = img.flipHorizontal(image);

  // 4. Filter
  image = _applyFilter(image, a.filter,
      brightness: a.brightness,
      contrast:   a.contrast,
      saturation: a.saturation);

  // 5. Save to temp dir (path received from main isolate)
  final outPath =
      p.join(a.tmpDir, 'nk_scan_${DateTime.now().microsecondsSinceEpoch}.jpg');
  await File(outPath).writeAsBytes(img.encodeJpg(image, quality: 92));
  return outPath;
}

Future<String> _compressInIsolate(
    String srcPath, String tmpDir, int quality) async {
  final bytes = await File(srcPath).readAsBytes();
  img.Image? image = img.decodeImage(bytes);
  if (image == null) return srcPath;
  final outPath =
      p.join(tmpDir, 'nk_comp_${DateTime.now().microsecondsSinceEpoch}.jpg');
  await File(outPath).writeAsBytes(img.encodeJpg(image, quality: quality));
  return outPath;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

img.Image _perspectiveCrop(img.Image src, DocumentCorners corners) {
  final w = src.width.toDouble();
  final h = src.height.toDouble();

  final tlX = (corners.topLeft.dx     * w).round().clamp(0, src.width  - 1);
  final tlY = (corners.topLeft.dy     * h).round().clamp(0, src.height - 1);
  final brX = (corners.bottomRight.dx * w).round().clamp(tlX + 1, src.width);
  final brY = (corners.bottomRight.dy * h).round().clamp(tlY + 1, src.height);

  return img.copyCrop(src,
      x: tlX, y: tlY, width: brX - tlX, height: brY - tlY);
}

img.Image _applyFilter(
  img.Image src,
  ScanFilter filter, {
  double brightness = 0.0,
  double contrast   = 1.0,
  double saturation = 1.0,
}) {
  img.Image out = src;

  switch (filter) {
    case ScanFilter.original:
      break;
    case ScanFilter.auto:
      out = img.adjustColor(out, contrast: 1.2, brightness: 1.05);
      break;
    case ScanFilter.magicColor:
      out = img.adjustColor(out, contrast: 1.3, saturation: 1.2, brightness: 1.05);
      break;
    case ScanFilter.blackAndWhite:
      out = img.grayscale(out);
      out = img.adjustColor(out, contrast: 1.6, brightness: 1.15);
      break;
    case ScanFilter.gray:
      out = img.grayscale(out);
      out = img.adjustColor(out, contrast: 1.2);
      break;
    case ScanFilter.color:
      out = img.adjustColor(out, contrast: 1.15, saturation: 1.15);
      break;
    case ScanFilter.document:
      out = img.grayscale(out);
      out = img.adjustColor(out, contrast: 1.5, brightness: 1.2);
      break;
    case ScanFilter.highContrast:
      out = img.adjustColor(out, contrast: 2.0, brightness: 1.1);
      break;
    case ScanFilter.sharpen:
      out = img.adjustColor(out, contrast: 1.3);
      break;
    case ScanFilter.cleanPaper:
      out = img.grayscale(out);
      out = img.adjustColor(out, brightness: 1.3, contrast: 1.4);
      break;
    case ScanFilter.vintage:
      out = img.adjustColor(out, saturation: 0.6, contrast: 0.9, brightness: 0.95);
      break;
  }

  if (brightness != 0.0 || contrast != 1.0 || saturation != 1.0) {
    out = img.adjustColor(out,
        brightness: 1.0 + brightness,
        contrast:   contrast,
        saturation: saturation);
  }

  return out;
}
