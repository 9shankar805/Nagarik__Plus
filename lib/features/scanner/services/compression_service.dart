import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Compresses JPEG images at various quality levels using flutter_image_compress
/// (native platform codec — far better quality than dart-only image package).
class CompressionService {
  CompressionService._();
  static final CompressionService instance = CompressionService._();

  /// Quality presets (percent).
  static const q90 = 90;
  static const q80 = 80;
  static const q70 = 70;
  static const q50 = 50;

  /// Compress [srcPath] JPEG to [quality] (0–100).
  /// Returns path to the compressed file (in temp dir).
  Future<String> compress(String srcPath, {int quality = q80}) async {
    final dir = await getTemporaryDirectory();
    final outPath = p.join(
        dir.path, 'nk_c${quality}_${DateTime.now().millisecondsSinceEpoch}.jpg');

    final result = await FlutterImageCompress.compressAndGetFile(
      srcPath,
      outPath,
      quality: quality,
      format: CompressFormat.jpeg,
    );

    return result?.path ?? srcPath;
  }

  /// Compress to bytes (useful when embedding in PDF).
  Future<List<int>> compressToBytes(String srcPath, {int quality = q80}) async {
    final bytes = await File(srcPath).readAsBytes();
    final result = await FlutterImageCompress.compressWithList(
      bytes,
      quality: quality,
      format: CompressFormat.jpeg,
    );
    return result;
  }

  /// Returns file size in KB.
  Future<double> fileSizeKb(String path) async {
    final f = File(path);
    if (!await f.exists()) return 0;
    return (await f.length()) / 1024;
  }
}
