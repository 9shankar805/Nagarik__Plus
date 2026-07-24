import 'package:flutter/foundation.dart';
import '../models/road_sign.dart';
import '../repositories/learning_repository.dart';

enum LearningStatus { initial, loading, loaded, error }

class LearningProvider extends ChangeNotifier {
  final LearningRepository _repository;

  LearningStatus _status = LearningStatus.initial;
  List<RoadSign> _roadSigns = [];
  List<QuizQuestion> _quizQuestions = [];
  List<Map<String, dynamic>> _quizHistory = [];
  String? _errorMessage;

  LearningStatus get status => _status;
  List<RoadSign> get roadSigns => _roadSigns;
  List<QuizQuestion> get quizQuestions => _quizQuestions;
  List<Map<String, dynamic>> get quizHistory => _quizHistory;
  String? get errorMessage => _errorMessage;

  LearningProvider({LearningRepository? repository})
      : _repository = repository ?? LearningRepository();

  Future<void> loadRoadSigns() async {
    _status = LearningStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _roadSigns = await _repository.getRoadSigns();
      _status = LearningStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = LearningStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadQuizQuestions({String? category}) async {
    _status = LearningStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _quizQuestions = await _repository.getQuestions(category: category);
      _status = LearningStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _status = LearningStatus.error;
    }
    notifyListeners();
  }

  Future<Map<String, dynamic>> submitQuiz(Map<String, dynamic> payload) async {
    try {
      return await _repository.submitAnswers(payload);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    }
  }

  Future<void> loadQuizHistory() async {
    try {
      _quizHistory = await _repository.getHistory();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    }
  }
}
