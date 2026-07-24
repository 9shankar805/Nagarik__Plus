import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/scan_document.dart';
import 'encryption_service.dart';

/// Handles all export / share operations for scanned documents.
class ShareService {
  ShareService._();
  static final ShareService instance = ShareService._();

  // ── Share normal PDF ──────────────────────────────────────────────────────

  Future<void> sharePdf(String pdfPath, {String? subject}) async {
    if (!File(pdfPath).existsSync()) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(pdfPath, mimeType: 'application/pdf')],
        subject: subject ?? 'Nagarik+ Document',
      ),
    );
  }

  // ── Share image ───────────────────────────────────────────────────────────

  Future<void> shareImage(String imagePath) async {
    if (!File(imagePath).existsSync()) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(imagePath, mimeType: 'image/jpeg')],
        subject: 'Nagarik+ Scan',
      ),
    );
  }

  // ── Share encrypted PDF ───────────────────────────────────────────────────

  Future<void> shareEncryptedPdf(String pdfPath) async {
    final encPath = await EncryptionService.instance.encryptFile(pdfPath);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(encPath, mimeType: 'application/octet-stream')],
        subject: 'Nagarik+ Encrypted Document',
        text: 'Open with Nagarik+ to decrypt.',
      ),
    );
  }

  // ── Export pages as PDF then share ───────────────────────────────────────

  Future<void> exportAndSharePages({
    required List<ScanPage> pages,
    required String documentName,
  }) async {
    final pdfDoc = pw.Document(title: documentName);
    for (final page in pages) {
      final bytes = await File(page.processedPath).readAsBytes();
      pdfDoc.addPage(pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Center(
            child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain)),
      ));
    }

    final dir  = await getTemporaryDirectory();
    final path = p.join(dir.path,
        '${documentName.replaceAll(RegExp(r'[^\w]'), '_')}_export.pdf');
    await File(path).writeAsBytes(await pdfDoc.save());

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: 'application/pdf')],
        subject: documentName,
      ),
    );
  }
}
