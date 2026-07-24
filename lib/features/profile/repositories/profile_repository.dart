import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../auth/models/user_model.dart';
import '../services/profile_api_service.dart';

class ProfileRepository {
  final ProfileApiService _apiService;
  final FlutterSecureStorage _storage;

  ProfileRepository({
    ProfileApiService? apiService,
    FlutterSecureStorage? storage,
  })  : _apiService = apiService ?? ProfileApiService(),
        _storage = storage ?? const FlutterSecureStorage();

  Future<User> getProfile() async {
    final response = await _apiService.getProfile();
    return response.data!;
  }

  Future<User> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiService.updateProfile(data);
    return response.data!;
  }

  Future<User> uploadAvatar(File file) async {
    final response = await _apiService.uploadAvatar(file);
    return response.data!;
  }
}
