
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

class AuthApiService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<AuthResponse>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? passwordConfirmation,
  }) async {
    return await _apiClient.post(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation ?? password,
      },
      fromJsonT: (json) => AuthResponse.fromJson(json),
    );
  }

  Future<ApiResponse<AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    return await _apiClient.post(
      '/auth/login',
      data: {'email': email, 'password': password},
      fromJsonT: (json) => AuthResponse.fromJson(json),
    );
  }

  Future<ApiResponse<AuthResponse>> loginWithPin({
    required String pin,
  }) async {
    return await _apiClient.post(
      '/auth/login/pin',
      data: {'pin': pin},
      fromJsonT: (json) => AuthResponse.fromJson(json),
    );
  }

  Future<ApiResponse<User>> getProfile() async {
    return await _apiClient.get(
      '/auth/profile',
      fromJsonT: (json) => User.fromJson(json),
    );
  }

  Future<ApiResponse<User>> updateProfile(Map<String, dynamic> data) async {
    return await _apiClient.put(
      '/auth/profile',
      data: data,
      fromJsonT: (json) => User.fromJson(json),
    );
  }

  Future<ApiResponse<void>> setPin(String pin) async {
    return await _apiClient.post(
      '/auth/pin',
      data: {'pin': pin},
    );
  }

  Future<ApiResponse<void>> changePin({required String currentPin, required String newPin}) async {
    return await _apiClient.post(
      '/auth/pin',
      data: {
        'current_pin': currentPin,
        'pin': newPin,
      },
    );
  }

  Future<ApiResponse<void>> logout() async {
    return await _apiClient.post('/auth/logout');
  }
}

