
import 'package:hive_flutter/hive_flutter.dart';
import '../services/ai_api_service.dart';
import '../models/ai_suggestion.dart';
import '../models/chat_message.dart';

class AiRepository {
  final AiApiService _apiService;
  final Box<ChatMessage>? _chatHistoryBox;

  AiRepository({
    AiApiService? apiService,
    Box<ChatMessage>? chatHistoryBox,
  })  : _apiService = apiService ?? AiApiService(),
        _chatHistoryBox = chatHistoryBox;

  Future<List<AiSuggestion>> getSuggestions() async {
    try {
      final response = await _apiService.getSuggestions();
      return response.data ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<List<ChatMessage>> getHistory({bool forceRefresh = false}) async {
    if (_chatHistoryBox != null && !forceRefresh && _chatHistoryBox!.isNotEmpty) {
      return _chatHistoryBox!.values.toList();
    }

    try {
      final response = await _apiService.getHistory();
      final history = response.data ?? [];
      if (_chatHistoryBox != null) {
        await _chatHistoryBox!.clear();
        await _chatHistoryBox!.addAll(history);
      }
      return history;
    } catch (e) {
      if (_chatHistoryBox != null && _chatHistoryBox!.isNotEmpty) {
        return _chatHistoryBox!.values.toList();
      }
      return [];
    }
  }

  Future<ChatMessage> sendMessage(String message) async {
    try {
      final response = await _apiService.sendMessage(message);
      if (_chatHistoryBox != null) {
        await _chatHistoryBox!.add(response.data!);
      }
      return response.data!;
    } catch (e) {
      rethrow;
    }
  }
}
