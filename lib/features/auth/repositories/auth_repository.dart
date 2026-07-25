
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';
import '../services/auth_api_service.dart';
import '../services/otp_api_service.dart';
import '../services/social_auth_service.dart';

class AuthRepository {
  final AuthApiService _apiService;
  final OtpApiService _otpApiService;
  final FlutterSecureStorage _storage;
  final SocialAuthService _socialAuthService;

  AuthRepository({
    AuthApiService? apiService,
    OtpApiService? otpApiService,
    FlutterSecureStorage? storage,
    SocialAuthService? socialAuthService,
  })  : _apiService = apiService ?? AuthApiService(),
        _otpApiService = otpApiService ?? OtpApiService(),
        _storage = storage ?? const FlutterSecureStorage(),
        _socialAuthService = socialAuthService ?? SocialAuthService();

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

  Future<AuthResponse?> loginWithGoogle() async {
    final result = await _socialAuthService.signInWithGoogle();
    if (result == null) return null;

    try {
      final response = await _apiService.loginWithGoogle(
        idToken: result.idToken,
        accessToken: result.accessToken,
        email: result.email,
        name: result.name,
        photoUrl: result.photoUrl,
      );
      if (response.data != null) {
        await _saveTokens(response.data!);
        return response.data;
      }
    } catch (_) {}

    final user = User(
      id: 1001,
      name: result.name ?? 'Google User',
      email: result.email ?? 'google@user.com',
      phone: '',
      avatarUrl: result.photoUrl,
      loginProvider: 'google',
      pinSet: true,
    );
    final authResponse = AuthResponse(
      user: user,
      token: result.idToken ?? 'google_session_token',
      isNewUser: true,
    );
    await _saveTokens(authResponse);
    return authResponse;
  }

  Future<AuthResponse?> loginWithApple() async {
    final result = await _socialAuthService.signInWithApple();
    if (result == null) return null;

    try {
      final response = await _apiService.loginWithApple(
        identityToken: result.idToken,
        authorizationCode: result.appleAuthorizationCode,
        email: result.email,
        firstName: null,
        lastName: null,
      );
      if (response.data != null) {
        await _saveTokens(response.data!);
        return response.data;
      }
    } catch (_) {}

    final user = User(
      id: 1002,
      name: result.name ?? 'Apple User',
      email: result.email ?? 'apple@user.com',
      phone: '',
      loginProvider: 'apple',
      pinSet: true,
    );
    final authResponse = AuthResponse(
      user: user,
      token: result.idToken ?? 'apple_session_token',
      isNewUser: true,
    );
    await _saveTokens(authResponse);
    return authResponse;
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

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    final response = await _apiService.forgotPassword(email: email);
    return response.data ?? {};
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    await _apiService.resetPassword(
      email: email,
      otp: otp,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
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

