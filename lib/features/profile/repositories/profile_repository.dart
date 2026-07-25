import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../auth/models/user_model.dart';
import '../../auth/repositories/auth_repository.dart';
import '../services/profile_api_service.dart';

class ProfileRepository {
  final ProfileApiService _apiService;
  final FlutterSecureStorage _storage;
  final AuthRepository? _authRepository;

  ProfileRepository({
    ProfileApiService? apiService,
    FlutterSecureStorage? storage,
    AuthRepository? authRepository,
  })  : _apiService = apiService ?? ProfileApiService(),
        _storage = storage ?? const FlutterSecureStorage(),
        _authRepository = authRepository;

  Future<User> getProfile() async {
    try {
      final response = await _apiService.getProfile();
      if (response.data != null) {
        final user = response.data!;
        try {
          final authRepo = _authRepository ?? AuthRepository(storage: _storage);
          await authRepo.saveCachedUser(user);
        } catch (_) {}
        return user;
      }
    } catch (_) {}
    try {
      final authRepo = _authRepository ?? AuthRepository(storage: _storage);
      final cached = await authRepo.getCachedUser();
      if (cached != null) return cached;
    } catch (_) {}
    throw Exception('Unable to load profile');
  }

  Future<User> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiService.updateProfile(data);
    final user = response.data!;
    try {
      final authRepo = _authRepository ?? AuthRepository(storage: _storage);
      await authRepo.saveCachedUser(user);
    } catch (_) {}
    return user;
  }

  Future<User> uploadAvatar(File file) async {
    final response = await _apiService.uploadAvatar(file);
    final user = response.data!;
    try {
      final authRepo = _authRepository ?? AuthRepository(storage: _storage);
      await authRepo.saveCachedUser(user);
    } catch (_) {}
    return user;
  }
}
