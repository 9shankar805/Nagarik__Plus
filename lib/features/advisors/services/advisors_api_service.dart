import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/advisor_model.dart';

class AdvisorsApiService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<List<Advisor>>> getAdvisors({
    String? category,
    String? search,
    bool? onlyOnline,
  }) async {
    final params = <String, dynamic>{};
    if (category != null) params['category'] = category;
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (onlyOnline == true) params['online'] = '1';

    return await _apiClient.get(
      '/advisors',
      queryParameters: params,
      fromJsonT: (json) {
        final rawList = (json is Map && json['data'] != null)
            ? json['data'] as List
            : (json is List ? json : []);
        return rawList
            .map((item) => Advisor.fromJson(item as Map<String, dynamic>))
            .toList();
      },
    );
  }

  Future<ApiResponse<Advisor>> getAdvisorById(String id) async {
    return await _apiClient.get(
      '/advisors/$id',
      fromJsonT: (json) {
        final rawMap = (json is Map && json['data'] != null)
            ? json['data'] as Map<String, dynamic>
            : json as Map<String, dynamic>;
        return Advisor.fromJson(rawMap);
      },
    );
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> getMyConsultations() async {
    return await _apiClient.get(
      '/consultations/my-bookings',
      fromJsonT: (json) {
        final rawList = (json is Map && json['data'] != null)
            ? json['data'] as List
            : (json is List ? json : []);
        return rawList.map((item) => item as Map<String, dynamic>).toList();
      },
    );
  }
}
