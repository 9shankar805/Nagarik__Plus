import '../models/road_sign.dart';
import '../services/learning_api_service.dart';

class LearningRepository {
  final LearningApiService _apiService;

  LearningRepository({LearningApiService? apiService})
      : _apiService = apiService ?? LearningApiService();

  Future<List<RoadSign>> getRoadSigns() async {
    final response = await _apiService.getRoadSigns();
    return response.data ?? [];
  }

  Future<List<QuizQuestion>> getQuestions({String? category}) async {
    final response = await _apiService.getQuestions(category: category);
    return response.data ?? [];
  }

  Future<Map<String, dynamic>> submitAnswers(Map<String, dynamic> payload) async {
    final response = await _apiService.submitAnswers(payload);
    return response.data ?? {};
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final response = await _apiService.getHistory();
    return response.data ?? [];
  }
}
