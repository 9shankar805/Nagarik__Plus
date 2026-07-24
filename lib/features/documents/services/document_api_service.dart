import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/document_model.dart';

class DocumentApiService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<List<DocumentModel>>> getDocuments() async {
    return await _apiClient.get(
      '/documents',
      fromJsonT: (json) {
        final rawList = (json is Map && json['documents'] != null)
            ? json['documents'] as List
            : (json is List ? json : []);
        return rawList
            .map((item) => DocumentModel.fromJson(item as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<ApiResponse<List<DocumentModel>>> getExpiringDocuments() async {
    return await _apiClient.get(
      '/documents/expiring',
      fromJsonT: (json) {
        final rawList = json is List ? json : (json is Map && json['data'] != null ? json['data'] as List : []);
        return rawList
            .map((item) => DocumentModel.fromJson(item as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<ApiResponse<DocumentModel>> getDocument(int id) async {
    return await _apiClient.get(
      '/documents/$id',
      fromJsonT: (json) => DocumentModel.fromJson(json is Map<String, dynamic> ? json : {}),
    );
  }

  Future<ApiResponse<DocumentModel>> createDocument(
    Map<String, dynamic> data,
  ) async {
    return await _apiClient.post(
      '/documents',
      data: data,
      fromJsonT: (json) => DocumentModel.fromJson(json is Map<String, dynamic> ? json : {}),
    );
  }

  Future<ApiResponse<DocumentModel>> uploadDocument(
    FormData formData, {
    Function(int, int)? onSendProgress,
  }) async {
    return await _apiClient.upload(
      '/documents',
      data: formData,
      onSendProgress: onSendProgress,
      fromJsonT: (json) => DocumentModel.fromJson(json is Map<String, dynamic> ? json : {}),
    );
  }

  Future<ApiResponse<DocumentModel>> updateDocument(
    int id,
    Map<String, dynamic> data,
  ) async {
    return await _apiClient.put(
      '/documents/$id',
      data: data,
      fromJsonT: (json) => DocumentModel.fromJson(json is Map<String, dynamic> ? json : {}),
    );
  }

  Future<ApiResponse<void>> deleteDocument(int id) async {
    return await _apiClient.delete('/documents/$id');
  }

  Future<ApiResponse<void>> downloadDocument(int id) async {
    return await _apiClient.get('/documents/$id/download');
  }
}
