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
        final userJson = json['user'] ?? json;
        return User(
          id: userJson['id'],
          name: userJson['name'],
          email: userJson['email'],
          phone: userJson['phone'],
          avatarUrl: userJson['avatar_url'],
          dob: userJson['dob'],
          address: userJson['address'],
          citizenshipNumber: userJson['citizenship_number'],
          pinSet: userJson['pin_set'] ?? false,
          biometricEnabled: userJson['biometric_enabled'] ?? false,
          createdAt: userJson['created_at'] != null ? DateTime.tryParse(userJson['created_at']) : null,
          documentCount: json['document_count'] ?? userJson['document_count'],
          reminderCount: json['reminder_count'] ?? userJson['reminder_count'],
        );
      },
    );
  }

  Future<ApiResponse<User>> updateProfile(Map<String, dynamic> data) async {
    return await _apiClient.put(
      '/auth/profile',
      data: data,
      fromJsonT: (json) {
        final userJson = json['data'] ?? json['user'] ?? json;
        return User(
          id: userJson['id'],
          name: userJson['name'],
          email: userJson['email'],
          phone: userJson['phone'],
          avatarUrl: userJson['avatar_url'],
          dob: userJson['dob'],
          address: userJson['address'],
          citizenshipNumber: userJson['citizenship_number'],
          pinSet: userJson['pin_set'] ?? false,
          biometricEnabled: userJson['biometric_enabled'] ?? false,
          createdAt: userJson['created_at'] != null ? DateTime.tryParse(userJson['created_at']) : null,
          documentCount: userJson['document_count'],
          reminderCount: userJson['reminder_count'],
        );
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
        final userJson = json['data'] ?? json['user'] ?? json;
        return User(
          id: userJson['id'],
          name: userJson['name'],
          email: userJson['email'],
          phone: userJson['phone'],
          avatarUrl: userJson['avatar_url'],
          dob: userJson['dob'],
          address: userJson['address'],
          citizenshipNumber: userJson['citizenship_number'],
          pinSet: userJson['pin_set'] ?? false,
          biometricEnabled: userJson['biometric_enabled'] ?? false,
          createdAt: userJson['created_at'] != null ? DateTime.tryParse(userJson['created_at']) : null,
          documentCount: userJson['document_count'],
          reminderCount: userJson['reminder_count'],
        );
      },
    );
  }
}
