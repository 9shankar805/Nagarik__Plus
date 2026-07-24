
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/ai_suggestion.dart';
import '../models/chat_message.dart';

class AiApiService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<List<AiSuggestion>>> getSuggestions() async {
    return await _apiClient.get(
      '/ai/suggestions',
      fromJsonT: (json) => (json as List)
          .map((item) => AiSuggestion.fromJson(item))
          .toList(),
    );
  }

  Future<ApiResponse<List<ChatMessage>>> getHistory() async {
    return await _apiClient.get(
      '/ai/history',
      fromJsonT: (json) => (json as List)
          .map((item) => ChatMessage.fromJson(item))
          .toList(),
    );
  }

  Future<ApiResponse<ChatMessage>> sendMessage(String message) async {
    return await _apiClient.post(
      '/ai/chat',
      data: {'message': message},
      fromJsonT: (json) => ChatMessage.fromJson(json),
    );
  }
}
