import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_document.dart';

/// Persists [ScanDocument] metadata (JSON index) + raw file management.
/// Encrypted file handling is delegated to EncryptionService at the
/// controller level.
class ScannerRepository {
  ScannerRepository._();
  static final ScannerRepository instance = ScannerRepository._();

  static const _indexKey = 'nagarik_scan_index_v1';

  // ── Save ─────────────────────────────────────────────────────────────────

  Future<void> saveDocument(ScanDocument doc) async {
    final index = await _loadIndex();
    index[doc.id] = _toJson(doc);
    await _persistIndex(index);
  }

  // ── Load ─────────────────────────────────────────────────────────────────

  Future<List<ScanDocument>> loadAll() async {
    final index = await _loadIndex();
    return index.values
        .map((v) => _fromJson(v as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<ScanDocument?> loadById(String id) async {
    final index = await _loadIndex();
    final v = index[id];
    if (v == null) return null;
    return _fromJson(v as Map<String, dynamic>);
  }

  // ── Delete ───────────────────────────────────────────────────────────────

  Future<void> deleteDocument(String id) async {
    final index = await _loadIndex();
    final entry = index.remove(id);
    if (entry != null) {
      final doc = _fromJson(entry as Map<String, dynamic>);
      // Delete all page files
      for (final page in doc.pages) {
        _tryDelete(page.processedPath);
        _tryDelete(page.originalPath);
      }
      if (doc.savedPdfPath != null) _tryDelete(doc.savedPdfPath!);
    }
    await _persistIndex(index);
  }

  // ── Directory helpers ─────────────────────────────────────────────────────

  Future<Directory> vaultDir(DocCategory category) async {
    final base = await getApplicationDocumentsDirectory();
    final sub  = _categoryFolder(category);
    final dir  = Directory(p.join(base.path, 'NagarikVault', sub));
    await dir.create(recursive: true);
    return dir;
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _loadIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getString(_indexKey);
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> _persistIndex(Map<String, dynamic> index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_indexKey, jsonEncode(index));
  }

  void _tryDelete(String path) {
    try { File(path).deleteSync(); } catch (_) {}
  }

  String _categoryFolder(DocCategory cat) {
    switch (cat) {
      case DocCategory.passport:            return 'Passport';
      case DocCategory.pan:                 return 'PAN';
      case DocCategory.citizenship:         return 'ID';
      case DocCategory.drivingLicense:      return 'DrivingLicense';
      case DocCategory.birthCertificate:    return 'Birth';
      case DocCategory.academicCertificate: return 'Academic';
      case DocCategory.insurance:           return 'Insurance';
      case DocCategory.bluebook:            return 'BlueBook';
      case DocCategory.medical:             return 'Medical';
      case DocCategory.property:            return 'Property';
      case DocCategory.vehicle:             return 'Vehicle';
      case DocCategory.other:               return 'Documents';
    }
  }

  Map<String, dynamic> _toJson(ScanDocument doc) => {
    'id':          doc.id,
    'name':        doc.name,
    'category':    doc.category.name,
    'pages':       doc.pages.map((pg) => {
      'id':              pg.id,
      'originalPath':    pg.originalPath,
      'processedPath':   pg.processedPath,
      'filter':          pg.filter.name,
      'brightness':      pg.brightness,
      'contrast':        pg.contrast,
      'saturation':      pg.saturation,
      'rotationDegrees': pg.rotationDegrees,
      'isFlippedH':      pg.isFlippedHorizontal,
    }).toList(),
    'createdAt':   doc.createdAt.toIso8601String(),
    'updatedAt':   doc.updatedAt.toIso8601String(),
    'savedPdfPath': doc.savedPdfPath,
    'ocrText':     doc.ocrText,
    'tags':        doc.tags,
    'expiryDate':  doc.expiryDate?.toIso8601String(),
  };

  ScanDocument _fromJson(Map<String, dynamic> j) => ScanDocument(
    id:           j['id'] as String,
    name:         j['name'] as String,
    category:     DocCategory.values.firstWhere(
        (c) => c.name == j['category'], orElse: () => DocCategory.other),
    pages:        (j['pages'] as List).map((pg) {
      final m = pg as Map<String, dynamic>;
      return ScanPage(
        id:              m['id'] as String,
        originalPath:    m['originalPath'] as String,
        processedPath:   m['processedPath'] as String,
        filter:          ScanFilter.values.firstWhere(
            (f) => f.name == m['filter'], orElse: () => ScanFilter.auto),
        brightness:      (m['brightness'] as num).toDouble(),
        contrast:        (m['contrast'] as num).toDouble(),
        saturation:      (m['saturation'] as num).toDouble(),
        rotationDegrees: m['rotationDegrees'] as int,
        isFlippedHorizontal: m['isFlippedH'] as bool,
      );
    }).toList(),
    createdAt:    DateTime.parse(j['createdAt'] as String),
    updatedAt:    DateTime.parse(j['updatedAt'] as String),
    savedPdfPath: j['savedPdfPath'] as String?,
    ocrText:      j['ocrText'] as String?,
    tags:         List<String>.from(j['tags'] as List? ?? []),
    expiryDate:   j['expiryDate'] != null
        ? DateTime.parse(j['expiryDate'] as String) : null,
  );
}
