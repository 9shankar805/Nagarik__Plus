import 'package:shared_preferences/shared_preferences.dart';
import '../models/document_model.dart';
import '../../../core/constants/app_assets.dart';

class DocumentService {
  static const _key = 'local_documents_v1';

  // ── Seed data — documents pre-loaded locally ─────────────────────────────
  static List<DocumentModel> get seedDocuments => [
    DocumentModel(
      id: 'national_id',
      title: 'National ID',
      subtitle: 'NID: 1234-5678-9012',
      type: 'national_id',
      category: 'Identity',
      assetImagePath: AppAssets.nationalId,
      isUploaded: true,
      fields: {
        'NID Number': '1234-5678-9012',
        'Full Name': 'Ram Bahadur Thapa',
        'Date of Birth': '2045-06-15',
        'Gender': 'Male',
        'Address': 'Kathmandu, Bagmati Province',
      },
    ),
    DocumentModel(
      id: 'driving_license',
      title: 'Driving License',
      subtitle: 'No: 02-78-002345',
      type: 'driving_license',
      category: 'Identity',
      assetImagePath: AppAssets.drivingLicense,
      expiryDate: DateTime(2025, 6, 15),
      isUploaded: true,
      fields: {
        'License No': '02-78-002345',
        'Full Name': 'Ram Bahadur Thapa',
        'Issue Date': '2020-06-15',
        'Expiry Date': '2025-06-15',
        'Category': 'A, B',
      },
    ),
    DocumentModel(
      id: 'pan',
      title: 'PAN Card',
      subtitle: 'PAN: 302456789',
      type: 'pan',
      category: 'Finance',
      assetImagePath: AppAssets.pan,
      isUploaded: true,
      fields: {
        'PAN Number': '302456789',
        'Full Name': 'Ram Bahadur Thapa',
        'Issue Date': '2019-03-20',
        'Tax Office': 'Kathmandu IRD',
      },
    ),
    DocumentModel(
      id: 'citizenship',
      title: 'Citizenship',
      subtitle: 'No: 040-02-54321',
      type: 'citizenship',
      category: 'Identity',
      assetImagePath: AppAssets.cims,
      isUploaded: true,
      fields: {
        'Citizenship No': '040-02-54321',
        'Full Name': 'Ram Bahadur Thapa',
        'Date of Birth': '2045-06-15',
        'Issue District': 'Kathmandu',
        'Father Name': 'Hari Bahadur Thapa',
        'Mother Name': 'Sita Devi Thapa',
      },
    ),
    DocumentModel(
      id: 'passport',
      title: 'Passport',
      subtitle: 'No: Pa1234567',
      type: 'passport',
      category: 'Identity',
      assetImagePath: AppAssets.passport,
      expiryDate: DateTime(2028, 9, 20),
      isUploaded: true,
      fields: {
        'Passport No': 'Pa1234567',
        'Full Name': 'RAM BAHADUR THAPA',
        'Nationality': 'Nepali',
        'Date of Birth': '15 Jun 1988',
        'Issue Date': '20 Sep 2018',
        'Expiry Date': '20 Sep 2028',
        'Place of Issue': 'Kathmandu',
      },
    ),
    DocumentModel(
      id: 'voter_id',
      title: 'Voter ID',
      subtitle: 'Not uploaded yet',
      type: 'voter_id',
      category: 'Identity',
      assetImagePath: AppAssets.voterId,
      isUploaded: false,
      fields: {},
    ),
  ];

  // ── Load all documents (merges saved overrides with seed) ─────────────────
  Future<List<DocumentModel>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key);

    if (saved == null || saved.isEmpty) {
      // First run — persist seed data
      await _saveAll(seedDocuments);
      return seedDocuments;
    }

    return saved
        .map((s) => DocumentModel.fromJsonString(s))
        .toList();
  }

  // ── Save a single document (upsert) ──────────────────────────────────────
  Future<void> save(DocumentModel doc) async {
    final all = await loadAll();
    final idx = all.indexWhere((d) => d.id == doc.id);
    if (idx >= 0) {
      all[idx] = doc;
    } else {
      all.add(doc);
    }
    await _saveAll(all);
  }

  // ── Persist full list ─────────────────────────────────────────────────────
  Future<void> _saveAll(List<DocumentModel> docs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _key,
      docs.map((d) => d.toJsonString()).toList(),
    );
  }

  // ── Get single document by id ─────────────────────────────────────────────
  Future<DocumentModel?> getById(String id) async {
    final all = await loadAll();
    try {
      return all.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Reset to seed (for dev/testing) ──────────────────────────────────────
  Future<void> reset() async {
    await _saveAll(seedDocuments);
  }
}
