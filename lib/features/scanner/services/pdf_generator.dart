import 'dart:io';
import 'dart:isolate';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/scan_document.dart';

class PdfGenerator {
  PdfGenerator._();
  static final PdfGenerator instance = PdfGenerator._();

  /// Generate a PDF from [pages] in a background isolate so the UI never freezes.
  /// Returns the saved file path.
  Future<String> generate({
    required List<ScanPage> pages,
    required String documentName,
    required PdfPageSize pageSize,
    bool compressed = false,
    String? author,
  }) async {
    // Resolve the output directory on the main isolate (path_provider needs it)
    final docsDir = (await getApplicationDocumentsDirectory()).path;
    final outDir  = p.join(docsDir, 'NagarikVault', 'PDF');
    await Directory(outDir).create(recursive: true);

    final safeName =
        documentName.replaceAll(RegExp(r'[^a-zA-Z0-9_\- ]'), '_').trim();
    final outPath =
        p.join(outDir, '${safeName}_${DateTime.now().millisecondsSinceEpoch}.pdf');

    // Collect everything the isolate needs BEFORE spawning
    final args = _PdfArgs(
      imagePaths:   pages.map((pg) => pg.processedPath).toList(),
      outPath:      outPath,
      pageFormatId: pageSize.index,
      documentName: documentName,
      author:       author ?? 'Nagarik+',
    );

    // Heavy work in isolate — UI stays smooth
    await Isolate.run(() => _buildPdf(args));

    return outPath;
  }
}

// ── Isolate payload ────────────────────────────────────────────────────────────

class _PdfArgs {
  final List<String> imagePaths;
  final String outPath;
  final int pageFormatId;  // PdfPageSize.index
  final String documentName;
  final String author;

  _PdfArgs({
    required this.imagePaths,
    required this.outPath,
    required this.pageFormatId,
    required this.documentName,
    required this.author,
  });
}

Future<void> _buildPdf(_PdfArgs a) async {
  final pdfDoc = pw.Document(
    title:   a.documentName,
    author:  a.author,
    creator: 'Nagarik+ Document Scanner',
  );

  final format = _pdfFormat(a.pageFormatId);

  for (final path in a.imagePaths) {
    final imageBytes = await File(path).readAsBytes();
    final pdfImage   = pw.MemoryImage(imageBytes);

    pdfDoc.addPage(
      pw.Page(
        pageFormat: format,
        margin:     pw.EdgeInsets.zero,
        build:      (_) => pw.Center(
          child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
        ),
      ),
    );
  }

  final pdfBytes = await pdfDoc.save();
  await File(a.outPath).writeAsBytes(pdfBytes);
}

PdfPageFormat _pdfFormat(int id) {
  switch (id) {
    case 0:  return PdfPageFormat.a4;     // PdfPageSize.a4
    case 1:  return PdfPageFormat.letter; // PdfPageSize.letter
    default: return PdfPageFormat.a4;     // PdfPageSize.original → a4
  }
}
