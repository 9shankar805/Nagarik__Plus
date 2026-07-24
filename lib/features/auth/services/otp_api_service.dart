
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';

class OtpApiService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<void>> sendOtp(String phone) async {
    return await _apiClient.post(
      '/auth/send-otp',
      data: {'phone': phone},
    );
  }

  Future<ApiResponse<void>> verifyOtp(String phone, String otp) async {
    return await _apiClient.post(
      '/auth/verify-otp',
      data: {'phone': phone, 'otp': otp},
    );
  }

  Future<ApiResponse<void>> forgotPin(String phone) async {
    return await _apiClient.post(
      '/auth/forgot-pin',
      data: {'phone': phone},
    );
  }

  Future<ApiResponse<void>> resetPin(String phone, String otp, String pin) async {
    return await _apiClient.post(
      '/auth/reset-pin',
      data: {'phone': phone, 'otp': otp, 'pin': pin},
    );
  }
}

