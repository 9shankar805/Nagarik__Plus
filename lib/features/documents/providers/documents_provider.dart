import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/document_model.dart';
import '../repositories/document_repository.dart';

enum DocumentsStatus { initial, loading, loaded, error }

class DocumentsProvider extends ChangeNotifier {
  final DocumentRepository _repository;

  DocumentsStatus _status = DocumentsStatus.initial;
  List<DocumentModel> _documents = [];
  List<DocumentModel> _expiringDocuments = [];
  String? _errorMessage;
  double _uploadProgress = 0.0;
  bool _isUploading = false;

  DocumentsStatus get status => _status;
  List<DocumentModel> get documents => _documents;
  List<DocumentModel> get expiringDocuments => _expiringDocuments;
  String? get errorMessage => _errorMessage;
  double get uploadProgress => _uploadProgress;
  bool get isUploading => _isUploading;

  DocumentsProvider({DocumentRepository? repository})
      : _repository = repository ?? DocumentRepository();

  Future<void> loadDocuments({bool forceRefresh = false}) async {
    _status = DocumentsStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _documents = await _repository.getDocuments(forceRefresh: forceRefresh);
      try {
        _expiringDocuments = await _repository.getExpiringDocuments();
      } catch (_) {
        // Fallback filter locally if backend expiring route errors
        final now = DateTime.now();
        _expiringDocuments = _documents.where((doc) {
          if (doc.expiryDate == null) return false;
          final diff = doc.expiryDate!.difference(now).inDays;
          return diff >= 0 && diff <= 90;
        }).toList();
      }
      _status = DocumentsStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = DocumentsStatus.error;
    }
    notifyListeners();
  }

  Future<void> refreshDocuments() async {
    await loadDocuments(forceRefresh: true);
  }

  Future<void> addDocument(Map<String, dynamic> data) async {
    try {
      final doc = await _repository.createDocument(data);
      _documents.insert(0, doc);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<DocumentModel> uploadDocument(
    FormData formData, {
    Function(int, int)? onSendProgress,
  }) async {
    _isUploading = true;
    _uploadProgress = 0.0;
    notifyListeners();
    try {
      final doc = await _repository.uploadDocument(
        formData,
        onSendProgress: (sent, total) {
          if (total > 0) {
            _uploadProgress = sent / total;
            notifyListeners();
          }
          if (onSendProgress != null) {
            onSendProgress(sent, total);
          }
        },
      );
      _documents.insert(0, doc);
      _status = DocumentsStatus.loaded;
      return doc;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isUploading = false;
      _uploadProgress = 0.0;
      notifyListeners();
    }
  }

  Future<void> updateDoc(int id, Map<String, dynamic> data) async {
    try {
      final updatedDoc = await _repository.updateDocument(id, data);
      final index = _documents.indexWhere((d) => d.id == id.toString());
      if (index != -1) {
        _documents[index] = updatedDoc;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteDoc(int id) async {
    try {
      await _repository.deleteDocument(id);
      _documents.removeWhere((d) => d.id == id.toString());
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> downloadDoc(int id) async {
    try {
      await _repository.downloadDocument(id);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    }
  }
}
