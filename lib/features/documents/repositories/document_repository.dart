import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/document_api_service.dart';
import '../models/document_model.dart';

class DocumentRepository {
  final DocumentApiService _apiService;
  final Box<DocumentModel>? _box;

  DocumentRepository({DocumentApiService? apiService, Box<DocumentModel>? box})
      : _apiService = apiService ?? DocumentApiService(),
        _box = box;

  Future<List<DocumentModel>> getDocuments({bool forceRefresh = false}) async {
    if (_box != null && !forceRefresh && _box!.isNotEmpty) {
      return _box!.values.toList();
    }

    try {
      final response = await _apiService.getDocuments();
      final docs = response.data ?? [];
      if (_box != null) {
        await _box!.clear();
        await _box!.addAll(docs);
      }
      return docs;
    } catch (e) {
      if (_box != null && _box!.isNotEmpty) {
        return _box!.values.toList();
      }
      rethrow;
    }
  }

  Future<List<DocumentModel>> getExpiringDocuments() async {
    try {
      final response = await _apiService.getExpiringDocuments();
      return response.data ?? [];
    } catch (e) {
      rethrow;
    }
  }

  Future<DocumentModel> getDocument(int id) async {
    try {
      final response = await _apiService.getDocument(id);
      return response.data!;
    } catch (e) {
      rethrow;
    }
  }

  Future<DocumentModel> createDocument(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.createDocument(data);
      if (_box != null && response.data != null) {
        await _box!.add(response.data!);
      }
      return response.data!;
    } catch (e) {
      rethrow;
    }
  }

  Future<DocumentModel> uploadDocument(
    FormData formData, {
    Function(int, int)? onSendProgress,
  }) async {
    try {
      final response = await _apiService.uploadDocument(
        formData,
        onSendProgress: onSendProgress,
      );
      if (_box != null && response.data != null) {
        await _box!.add(response.data!);
      }
      return response.data!;
    } catch (e) {
      rethrow;
    }
  }

  Future<DocumentModel> updateDocument(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _apiService.updateDocument(id, data);
      if (_box != null && response.data != null) {
        final index = _box!.values.toList().indexWhere((d) => d.id == id.toString());
        if (index != -1) {
          await _box!.putAt(index, response.data!);
        }
      }
      return response.data!;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteDocument(int id) async {
    try {
      await _apiService.deleteDocument(id);
      if (_box != null) {
        final index = _box!.values.toList().indexWhere((d) => d.id == id.toString());
        if (index != -1) {
          await _box!.deleteAt(index);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> downloadDocument(int id) async {
    await _apiService.downloadDocument(id);
  }
}
