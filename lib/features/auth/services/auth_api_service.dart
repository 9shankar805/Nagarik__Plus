
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

  Future<ApiResponse<AuthResponse>> loginWithGoogle({
    String? idToken,
    String? accessToken,
    String? email,
    String? name,
    String? photoUrl,
  }) async {
    return await _apiClient.post(
      '/auth/google',
      data: {
        'id_token': idToken,
        'access_token': accessToken,
        'email': email,
        'name': name,
        'photo_url': photoUrl,
      },
      fromJsonT: (json) {
        final resp = AuthResponse.fromJson(json);
        if (resp.user.loginProvider == null) {
          return AuthResponse(
            token: resp.token,
            user: resp.user.copyWith(
              loginProvider: 'google',
              avatarUrl: resp.user.avatarUrl ?? photoUrl,
            ),
          );
        }
        if (resp.user.avatarUrl == null && photoUrl != null) {
          return AuthResponse(
            token: resp.token,
            user: resp.user.copyWith(avatarUrl: photoUrl),
          );
        }
        return resp;
      },
    );
  }

  Future<ApiResponse<AuthResponse>> loginWithApple({
    String? identityToken,
    String? authorizationCode,
    String? email,
    String? firstName,
    String? lastName,
    String? nonce,
    String? deviceId,
  }) async {
    return await _apiClient.post(
      '/auth/apple',
      data: {
        'identity_token': identityToken,
        'authorization_code': authorizationCode,
        'email': email,
        'user': firstName != null || lastName != null
            ? {
                'firstName': firstName,
                'lastName': lastName,
              }
            : null,
        'nonce': nonce,
        'device_id': deviceId,
      },
      fromJsonT: (json) {
        final resp = AuthResponse.fromJson(json);
        if (resp.user.loginProvider == null) {
          return AuthResponse(
            token: resp.token,
            user: resp.user.copyWith(loginProvider: 'apple'),
          );
        }
        return resp;
      },
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

  Future<ApiResponse<Map<String, dynamic>>> forgotPassword({
    required String email,
  }) async {
    return await _apiClient.post(
      '/auth/forgot-password',
      data: {'email': email},
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<void>> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    return await _apiClient.post(
      '/auth/reset-password',
      data: {
        'email': email,
        'otp': otp,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }
}

