import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/road_sign.dart';

class LearningApiService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<List<RoadSign>>> getRoadSigns() async {
    return await _apiClient.get(
      '/learning/road-signs',
      fromJsonT: (json) {
        final rawList = (json is Map && json['data'] != null)
            ? json['data'] as List
            : (json is List ? json : []);
        return rawList
            .map((item) => RoadSign.fromJson(item as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<ApiResponse<List<QuizQuestion>>> getQuestions({String? category}) async {
    final params = <String, dynamic>{};
    if (category != null) params['category'] = category;

    return await _apiClient.get(
      '/learning/questions',
      queryParameters: params,
      fromJsonT: (json) {
        final rawList = (json is Map && json['data'] != null)
            ? json['data'] as List
            : (json is List ? json : []);
        return rawList
            .map((item) => QuizQuestion.fromJson(item as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> submitAnswers(Map<String, dynamic> payload) async {
    return await _apiClient.post(
      '/learning/submit',
      data: payload,
      fromJsonT: (json) => json as Map<String, dynamic>,
    );
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getHistory() async {
    return await _apiClient.get(
      '/learning/history',
      fromJsonT: (json) {
        final rawList = (json is Map && json['data'] != null)
            ? json['data'] as List
            : (json is List ? json : []);
        return rawList.map((item) => item as Map<String, dynamic>).toList();
      },
    );
  }
}
