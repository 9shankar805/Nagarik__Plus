import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/scan_document.dart';
import '../services/image_processor.dart';
import '../services/pdf_generator.dart';
import '../services/ocr_service.dart';
import '../services/compression_service.dart';
import '../services/security_service.dart';
import '../repositories/scanner_repository.dart';

enum ScannerState { idle, capturing, processing, reviewing, saving, done, error }

class ScannerController extends ChangeNotifier {
  // ── State ─────────────────────────────────────────────────────────────────
  ScannerState _state = ScannerState.idle;
  ScannerState get state => _state;

  final List<ScanPage>    _pages     = [];
  List<ScanPage>          get pages  => List.unmodifiable(_pages);

  int _selectedPageIndex = 0;
  int get selectedPageIndex => _selectedPageIndex;
  ScanPage? get selectedPage =>
      _pages.isEmpty ? null : _pages[_selectedPageIndex];

  DocumentCorners _corners = DocumentCorners.fullFrame;
  DocumentCorners get corners => _corners;

  bool _docDetected = false;
  bool get docDetected => _docDetected;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  // Edit history for undo/redo
  final List<ScanPage> _undoStack = [];
  bool get canUndo => _undoStack.isNotEmpty;

  // ── Dependencies ──────────────────────────────────────────────────────────
  final _processor  = ImageProcessor.instance;
  final _pdfGen     = PdfGenerator.instance;
  final _compress   = CompressionService.instance;
  final _security   = SecurityService.instance;
  final _ocr        = OcrService.instance;
  final _repo       = ScannerRepository.instance;
  static const _uuid = Uuid();

  // ── Camera edge detection simulation ─────────────────────────────────────

  void onDocumentDetected(DocumentCorners corners, bool stable) {
    _corners     = corners;
    _docDetected = stable;
    notifyListeners();
  }

  // ── Capture ───────────────────────────────────────────────────────────────

  Future<void> captureAndProcess(String rawImagePath) async {
    _setState(ScannerState.capturing);
    _isProcessing = true;
    notifyListeners();

    try {
      final processed = await _processor.process(
        srcPath:  rawImagePath,
        corners:  _corners,
        filter:   ScanFilter.auto,
      );

      final page = ScanPage(
        id:            _uuid.v4(),
        originalPath:  rawImagePath,
        processedPath: processed,
      );

      _pages.add(page);
      _selectedPageIndex = _pages.length - 1;
      _setState(ScannerState.reviewing);
    } catch (e) {
      _setError('Capture failed: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Use this when the image is ALREADY cropped by the native scanner
  /// (e.g. cunning_document_scanner). Skips perspective correction and
  /// just applies the auto-enhance filter.
  Future<void> addPreCroppedPage(String croppedImagePath) async {
    _setState(ScannerState.capturing);
    _isProcessing = true;
    notifyListeners();

    try {
      // enhanceOnly: no perspective crop, just colour/contrast enhancement
      final processed = await _processor.enhanceOnly(
        srcPath: croppedImagePath,
        filter:  ScanFilter.auto,
      );

      final page = ScanPage(
        id:            _uuid.v4(),
        originalPath:  croppedImagePath,
        processedPath: processed,
      );

      _pages.add(page);
      _selectedPageIndex = _pages.length - 1;
      _setState(ScannerState.reviewing);
    } catch (e) {
      _setError('Enhance failed: $e');
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }


  // ── Page operations ───────────────────────────────────────────────────────

  void selectPage(int index) {
    if (index < 0 || index >= _pages.length) return;
    _selectedPageIndex = index;
    notifyListeners();
  }

  void deletePage(int index) {
    if (index < 0 || index >= _pages.length) return;
    _tryDeleteFile(_pages[index].processedPath);
    _pages.removeAt(index);
    _selectedPageIndex = (_selectedPageIndex >= _pages.length
        ? _pages.length - 1
        : _selectedPageIndex).clamp(0, _pages.length - 1);
    notifyListeners();
  }

  void reorderPages(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final page = _pages.removeAt(oldIndex);
    _pages.insert(newIndex, page);
    notifyListeners();
  }

  Future<void> rotatePage(int index, {bool clockwise = true}) async {
    if (index < 0 || index >= _pages.length) return;
    _pushUndo(_pages[index]);
    final newDeg =
        (_pages[index].rotationDegrees + (clockwise ? 90 : -90)) % 360;
    await _reprocessPage(index, rotationDeg: newDeg);
  }

  // ── Enhancement ───────────────────────────────────────────────────────────

  Future<void> applyFilter(ScanFilter filter) async {
    final idx = _selectedPageIndex;
    if (idx < 0 || idx >= _pages.length) return;
    _pushUndo(_pages[idx]);
    await _reprocessPage(idx, filter: filter);
  }

  Future<void> applyAdjustments({
    double? brightness,
    double? contrast,
    double? saturation,
  }) async {
    final idx = _selectedPageIndex;
    if (idx < 0 || idx >= _pages.length) return;
    _pushUndo(_pages[idx]);
    await _reprocessPage(idx,
        brightness: brightness,
        contrast:   contrast,
        saturation: saturation);
  }

  Future<void> flipHorizontal() async {
    final idx = _selectedPageIndex;
    if (idx < 0 || idx >= _pages.length) return;
    _pushUndo(_pages[idx]);
    final cur = _pages[idx];
    await _reprocessPage(idx, flipH: !cur.isFlippedHorizontal);
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final prev = _undoStack.removeLast();
    final idx  = _pages.indexWhere((p) => p.id == prev.id);
    if (idx == -1) return;
    _pages[idx] = prev;
    notifyListeners();
  }

  void resetPage() {
    final idx = _selectedPageIndex;
    if (idx < 0 || idx >= _pages.length) return;
    final cur = _pages[idx];
    _pushUndo(cur);
    _reprocessPage(idx,
        filter:     ScanFilter.auto,
        brightness: 0.0,
        contrast:   1.0,
        saturation: 1.0,
        rotationDeg: 0,
        flipH:      false);
  }

  void updateCorners(DocumentCorners corners) {
    _corners = corners;
    notifyListeners();
  }

  Future<void> reapplyCorners() async {
    final idx = _selectedPageIndex;
    if (idx < 0 || idx >= _pages.length) return;
    _pushUndo(_pages[idx]);
    await _reprocessPage(idx);
  }

  // ── Extract Text (OCR) ───────────────────────────────────────────────────

  /// Runs OCR on a single page and returns the extracted text.
  Future<String> extractTextFromPage(int index) async {
    if (index < 0 || index >= _pages.length) return '';
    try {
      return await _ocr.extractText(_pages[index].processedPath);
    } catch (_) {
      return '';
    }
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<ScanDocument?> saveDocument({
    required String name,
    required DocCategory category,
    required SaveFormat format,
    required PdfPageSize pageSize,
    bool runOcr       = false,
    bool compressed   = false,
    int  compressionQuality = 80,
    DateTime? expiryDate,
    List<String>? tags,
    void Function(String msg)? onProgress,
  }) async {
    if (_pages.isEmpty) return null;
    _setState(ScannerState.saving);

    try {
      onProgress?.call('Processing pages…');

      // ── Step 1: Compress if requested ────────────────────────────────────
      final pagesToSave = List<ScanPage>.from(_pages);
      if (compressed) {
        onProgress?.call('Compressing images…');
        for (int i = 0; i < pagesToSave.length; i++) {
          final cp = await _compress.compress(
              pagesToSave[i].processedPath,
              quality: compressionQuality);
          pagesToSave[i] = pagesToSave[i].copyWith(processedPath: cp);
        }
      }

      // ── Step 2: Copy page images to PERMANENT vault folder (background) ──
      // Must happen off main thread — high-res images can be several MB each.
      onProgress?.call('Saving images…');
      final vaultDir = await _repo.vaultDir(category);
      final vaultPath = vaultDir.path;
      final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');

      // Run file copies directly (simplified for cross-platform support)
      final dstPaths = <String>[];
      for (int i = 0; i < pagesToSave.length; i++) {
        final dst =
            '$vaultPath/${safeName}_p${i + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        await File(pagesToSave[i].processedPath).copy(dst);
        dstPaths.add(dst);
      }

      final permanentPages = <ScanPage>[];
      for (int i = 0; i < pagesToSave.length; i++) {
        permanentPages.add(pagesToSave[i].copyWith(processedPath: dstPaths[i]));
      }

      // ── Step 3: Generate PDF from permanent images ────────────────────────
      String? pdfPath;
      if (format == SaveFormat.pdf || permanentPages.length > 1) {
        onProgress?.call('Generating PDF…');
        pdfPath = await _pdfGen.generate(
          pages:        permanentPages,
          documentName: name,
          pageSize:     pageSize,
          compressed:   compressed,
        );
      }

      // ── Step 4: OCR (optional, slow) ──────────────────────────────────────
      String? ocrText;
      if (runOcr) {
        onProgress?.call('Extracting text (OCR)…');
        final buffer = StringBuffer();
        for (int i = 0; i < permanentPages.length; i++) {
          onProgress?.call('OCR page ${i + 1}/${permanentPages.length}…');
          final text = await _ocr.extractText(permanentPages[i].processedPath);
          buffer.writeln(text);
        }
        ocrText = buffer.toString().trim();
        if (category == DocCategory.other && ocrText.isNotEmpty) {
          final guessed = _ocr.classifyFromOcr(ocrText);
          category = DocCategory.values.firstWhere(
              (c) => c.name == guessed, orElse: () => DocCategory.other);
        }
      }

      // ── Step 5: Persist metadata ──────────────────────────────────────────
      onProgress?.call('Saving to vault…');
      final doc = ScanDocument(
        id:           const Uuid().v4(),
        name:         name,
        category:     category,
        pages:        permanentPages,       // permanent paths, not temp
        createdAt:    DateTime.now(),
        updatedAt:    DateTime.now(),
        savedPdfPath: pdfPath,
        ocrText:      ocrText,
        tags:         tags,
        expiryDate:   expiryDate,
      );

      await _repo.saveDocument(doc);

      // ── Step 6: Clean up temp files AFTER everything is saved ─────────────
      onProgress?.call('Done!');
      _security.cleanTempFiles(); // fire-and-forget — don't await

      _setState(ScannerState.done);
      return doc;
    } catch (e) {
      _setError('Save failed: $e');
      return null;
    }
  }


  // ── Reset session ─────────────────────────────────────────────────────────

  void reset() {
    // Clean temp files
    for (final page in _pages) {
      _tryDeleteFile(page.processedPath);
    }
    _pages.clear();
    _undoStack.clear();
    _selectedPageIndex = 0;
    _corners           = DocumentCorners.fullFrame;
    _docDetected       = false;
    _errorMessage      = null;
    _setState(ScannerState.idle);
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _reprocessPage(
    int idx, {
    ScanFilter?  filter,
    double?      brightness,
    double?      contrast,
    double?      saturation,
    int?         rotationDeg,
    bool?        flipH,
  }) async {
    _isProcessing = true;
    notifyListeners();

    final cur = _pages[idx];
    try {
      final processed = await _processor.process(
        srcPath:    cur.originalPath,
        corners:    _corners,
        filter:     filter     ?? cur.filter,
        brightness: brightness ?? cur.brightness,
        contrast:   contrast   ?? cur.contrast,
        saturation: saturation ?? cur.saturation,
        rotationDeg: rotationDeg ?? cur.rotationDegrees,
        flipH:      flipH      ?? cur.isFlippedHorizontal,
      );

      _pages[idx] = cur.copyWith(
        processedPath: processed,
        filter:        filter,
        brightness:    brightness,
        contrast:      contrast,
        saturation:    saturation,
        rotationDegrees: rotationDeg,
        isFlippedHorizontal: flipH,
      );
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void _pushUndo(ScanPage page) {
    _undoStack.add(page.copyWith());
    if (_undoStack.length > 20) _undoStack.removeAt(0);
  }

  void _setState(ScannerState s) {
    _state = s;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    _state = ScannerState.error;
    notifyListeners();
  }

  void _tryDeleteFile(String path) {
    try { File(path).deleteSync(); } catch (_) {}
  }

  @override
  void dispose() {
    _ocr.dispose();
    super.dispose();
  }
}
