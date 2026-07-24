import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Offline OCR powered by Google ML Kit on-device model.
/// Supports Latin script (covers English + Nepali romanised).
class OcrService {
  OcrService._();
  static final OcrService instance = OcrService._();

  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Extract all text from an image file.
  Future<String> extractText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final result = await _recognizer.processImage(inputImage);
      return result.text;
    } catch (_) {
      return '';
    }
  }

  /// Classify document type from extracted OCR text.
  /// Returns best-guess category based on keywords found.
  String classifyFromOcr(String text) {
    final t = text.toLowerCase();
    if (t.contains('passport') || t.contains('travel document')) {
      return 'passport';
    }
    if (t.contains('permanent account') || t.contains('pan')) {
      return 'pan';
    }
    if (t.contains('citizenship') || t.contains('nagarikta')) {
      return 'citizenship';
    }
    if (t.contains('driving') || t.contains('licence') || t.contains('license')) {
      return 'drivingLicense';
    }
    if (t.contains('birth') || t.contains('janma')) {
      return 'birthCertificate';
    }
    if (t.contains('insurance') || t.contains('policy')) {
      return 'insurance';
    }
    if (t.contains('bluebook') || t.contains('blue book') || t.contains('registration')) {
      return 'bluebook';
    }
    return 'other';
  }

  void dispose() => _recognizer.close();
}
