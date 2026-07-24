import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/document_model.dart';

class DocumentPdfPrinter {
  DocumentPdfPrinter._();
  static final DocumentPdfPrinter instance = DocumentPdfPrinter._();

  /// Build clean Top & Down PDF document bytes containing ONLY the uploaded document images
  Future<Uint8List> buildDocumentPdf(DocumentModel doc) async {
    final pdfDoc = pw.Document(
      title: '${doc.title} - Scanned Document Print',
      author: 'Nagarik Digital Locker',
    );

    // Load front image if available
    pw.MemoryImage? frontImage;
    if (doc.localFilePath != null && File(doc.localFilePath!).existsSync()) {
      final bytes = await File(doc.localFilePath!).readAsBytes();
      frontImage = pw.MemoryImage(bytes);
    } else if (doc.assetImagePath != null) {
      try {
        final bytes = await rootBundle.load(doc.assetImagePath!);
        frontImage = pw.MemoryImage(bytes.buffer.asUint8List());
      } catch (_) {}
    }

    // Load back image if available
    pw.MemoryImage? backImage;
    if (doc.localBackFilePath != null && File(doc.localBackFilePath!).existsSync()) {
      final bytes = await File(doc.localBackFilePath!).readAsBytes();
      backImage = pw.MemoryImage(bytes);
    }

    pdfDoc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 30),
        build: (pw.Context context) {
          if (frontImage == null && backImage == null) {
            return pw.Center(
              child: pw.Text(
                'No uploaded document photo available to print.\nPlease capture or upload ${doc.title} photo first.',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 13,
                  color: PdfColors.grey700,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            );
          }

          return pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.start,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Top Title Badge
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#003893'),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${doc.title.toUpperCase()} — UPLOADED DOCUMENT PRINT',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'NAGARIK+',
                      style: pw.TextStyle(
                        color: PdfColors.amber100,
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Front Document Image (TOP)
              if (frontImage != null) ...[
                pw.Text(
                  'FRONT SIDE',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#003893'),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Container(
                  width: 480,
                  height: 280,
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColor.fromHex('#94A3B8'), width: 1),
                  ),
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Center(
                    child: pw.Image(frontImage, fit: pw.BoxFit.contain),
                  ),
                ),
                pw.SizedBox(height: 24),
              ],

              // Back Document Image (DOWN / BOTTOM)
              if (backImage != null) ...[
                pw.Text(
                  'BACK SIDE',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#003893'),
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Container(
                  width: 480,
                  height: 280,
                  decoration: pw.BoxDecoration(
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: PdfColor.fromHex('#94A3B8'), width: 1),
                  ),
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Center(
                    child: pw.Image(backImage, fit: pw.BoxFit.contain),
                  ),
                ),
              ],

              pw.Spacer(),

              // Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Document ID: ${doc.id}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Printed via Nagarik+ Digital Locker: ${DateTime.now().toString().split('.').first}',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdfDoc.save();
  }

  /// Print document directly using system printing dialog
  Future<void> printDocument(DocumentModel doc) async {
    final pdfBytes = await buildDocumentPdf(doc);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: '${doc.title}_Document.pdf',
    );
  }

  /// Share PDF file via platform share dialog
  Future<void> sharePdf(DocumentModel doc) async {
    final pdfBytes = await buildDocumentPdf(doc);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '${doc.title.replaceAll(' ', '_')}_Document.pdf',
    );
  }

  /// Save PDF file to documents directory and return saved file path
  Future<String> savePdfFile(DocumentModel doc) async {
    final pdfBytes = await buildDocumentPdf(doc);
    final appDir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory('${appDir.path}/nagarik_pdf');
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }
    final filePath = p.join(
      pdfDir.path,
      '${doc.title.replaceAll(RegExp(r'[^\w]'), '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);
    return filePath;
  }
}
