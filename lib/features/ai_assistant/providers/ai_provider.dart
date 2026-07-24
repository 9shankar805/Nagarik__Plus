
import 'package:flutter/foundation.dart';
import '../models/ai_suggestion.dart';
import '../models/chat_message.dart';
import '../repositories/ai_repository.dart';

enum AiStatus { initial, loading, loaded, error }

class AiProvider extends ChangeNotifier {
  final AiRepository _repository;

  AiStatus _status = AiStatus.initial;
  List<AiSuggestion> _suggestions = [];
  List<ChatMessage> _messages = [];
  String? _errorMessage;

  AiStatus get status => _status;
  List<AiSuggestion> get suggestions => _suggestions;
  List<ChatMessage> get messages => _messages;
  String? get errorMessage => _errorMessage;

  AiProvider({AiRepository? repository})
      : _repository = repository ?? AiRepository();

  Future<void> loadSuggestions() async {
    try {
      _suggestions = await _repository.getSuggestions();
    } catch (e) {
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> loadHistory({bool forceRefresh = false}) async {
    _status = AiStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _messages = await _repository.getHistory(forceRefresh: forceRefresh);
      _status = AiStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = AiStatus.error;
    }
    notifyListeners();
  }

  Future<void> sendMessage(String message) async {
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    final typingMessage = ChatMessage(
      id: 'typing-${DateTime.now().millisecondsSinceEpoch}',
      content: '',
      isUser: false,
      isTyping: true,
    );

    _messages.add(userMessage);
    _messages.add(typingMessage);
    notifyListeners();

    try {
      final aiMessage = await _repository.sendMessage(message);
      _messages.removeLast();
      _messages.add(aiMessage);
    } catch (e) {
      _messages.removeLast();
      _errorMessage = e.toString();
    }
    notifyListeners();
  }
}
