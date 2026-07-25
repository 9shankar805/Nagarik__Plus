import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/call_model.dart';

class CallApiService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<CallInitiateResponse>> initiateCall(int receiverId, String type) async {
    return await _apiClient.post(
      '/calls/initiate',
      data: {
        'receiver_id': receiverId,
        'type': type,
      },
      fromJsonT: (json) => CallInitiateResponse.fromJson(json),
    );
  }

  Future<ApiResponse<CallInitiateResponse>> acceptCall(int callId) async {
    return await _apiClient.post(
      '/calls/accept',
      data: {'call_id': callId},
      fromJsonT: (json) => CallInitiateResponse.fromJson(json),
    );
  }

  Future<ApiResponse<CallInitiateResponse>> rejectCall(int callId) async {
    return await _apiClient.post(
      '/calls/reject',
      data: {'call_id': callId},
      fromJsonT: (json) => CallInitiateResponse.fromJson(json),
    );
  }

  Future<ApiResponse<CallInitiateResponse>> endCall(int callId) async {
    return await _apiClient.post(
      '/calls/end',
      data: {'call_id': callId},
      fromJsonT: (json) => CallInitiateResponse.fromJson(json),
    );
  }

  Future<ApiResponse<CallHistoryResponse>> getCallHistory({int page = 1}) async {
    return await _apiClient.get(
      '/calls/history',
      queryParameters: {'page': page},
      fromJsonT: (json) => CallHistoryResponse.fromJson(json),
    );
  }

  Future<ApiResponse<CallModel>> getCallDetails(int callId) async {
    return await _apiClient.get(
      '/calls/$callId',
      fromJsonT: (json) => CallModel.fromJson(json),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> getTurnCredentials() async {
    return await _apiClient.get(
      '/calls/turn',
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }
}
