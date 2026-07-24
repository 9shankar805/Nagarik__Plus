
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';
import '../services/auth_api_service.dart';
import '../services/otp_api_service.dart';

class AuthRepository {
  final AuthApiService _apiService;
  final OtpApiService _otpApiService;
  final FlutterSecureStorage _storage;

  AuthRepository({
    AuthApiService? apiService,
    OtpApiService? otpApiService,
    FlutterSecureStorage? storage,
  })  : _apiService = apiService ?? AuthApiService(),
        _otpApiService = otpApiService ?? OtpApiService(),
        _storage = storage ?? const FlutterSecureStorage();

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await _apiService.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
    );
    await _saveTokens(response.data!);
    return response.data!;
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.login(
      email: email,
      password: password,
    );
    await _saveTokens(response.data!);
    return response.data!;
  }

  Future<AuthResponse> loginWithPin({required String pin}) async {
    final response = await _apiService.loginWithPin(pin: pin);
    await _saveTokens(response.data!);
    return response.data!;
  }

  Future<User> getProfile() async {
    final response = await _apiService.getProfile();
    if (response.data != null) {
      await saveCachedUser(response.data!);
    }
    return response.data!;
  }

  Future<User> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiService.updateProfile(data);
    if (response.data != null) {
      await saveCachedUser(response.data!);
    }
    return response.data!;
  }

  Future<void> setPin(String pin) async {
    await _apiService.setPin(pin);
  }

  Future<void> changePin({required String currentPin, required String newPin}) async {
    await _apiService.changePin(currentPin: currentPin, newPin: newPin);
  }

  Future<void> logout() async {
    await _apiService.logout();
    await _clearStorage();
  }

  Future<void> sendOtp(String phone) async {
    await _otpApiService.sendOtp(phone);
  }

  Future<void> verifyOtp(String phone, String otp) async {
    await _otpApiService.verifyOtp(phone, otp);
  }

  Future<void> forgotPin(String phone) async {
    await _otpApiService.forgotPin(phone);
  }

  Future<void> resetPin(String phone, String otp, String pin) async {
    await _otpApiService.resetPin(phone, otp, pin);
  }

  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null;
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<User?> getCachedUser() async {
    final userJson = await _storage.read(key: 'auth_user');
    if (userJson != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(userJson) as Map<String, dynamic>;
        return User.fromJson(decoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> saveCachedUser(User user) async {
    await _storage.write(key: 'auth_user', value: jsonEncode(user.toJson()));
  }

  Future<void> _saveTokens(AuthResponse authResponse) async {
    await _storage.write(key: 'auth_token', value: authResponse.token);
    await saveCachedUser(authResponse.user);
  }

  Future<void> _clearStorage() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'auth_user');
  }
}

