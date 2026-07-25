import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../auth/models/user_model.dart';

class ProfileApiService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<User>> getProfile() async {
    return await _apiClient.get(
      '/auth/profile',
      fromJsonT: (json) {
        final userJson = (json['user'] ?? json) as Map<String, dynamic>;
        final user = User.fromJson(userJson);
        final docCount = json['document_count'] ?? userJson['document_count'];
        final remCount = json['reminder_count'] ?? userJson['reminder_count'];
        if (docCount != null || remCount != null) {
          return user.copyWith(
            documentCount: docCount as int?,
            reminderCount: remCount as int?,
          );
        }
        return user;
      },
    );
  }

  Future<ApiResponse<User>> updateProfile(Map<String, dynamic> data) async {
    return await _apiClient.put(
      '/auth/profile',
      data: data,
      fromJsonT: (json) {
        final userJson = (json['data'] ?? json['user'] ?? json) as Map<String, dynamic>;
        return User.fromJson(userJson);
      },
    );
  }

  Future<ApiResponse<User>> uploadAvatar(File file) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last.split('\\').last,
      ),
      '_method': 'PUT',
    });

    return await _apiClient.upload(
      '/auth/profile',
      data: formData,
      fromJsonT: (json) {
        final userJson = (json['data'] ?? json['user'] ?? json) as Map<String, dynamic>;
        return User.fromJson(userJson);
      },
    );
  }
}
