import '../models/advisor_model.dart';
import '../services/advisors_api_service.dart';

class AdvisorsRepository {
  final AdvisorsApiService _apiService;

  AdvisorsRepository({AdvisorsApiService? apiService})
      : _apiService = apiService ?? AdvisorsApiService();

  Future<List<Advisor>> getAdvisors({
    String? category,
    String? search,
    bool? onlyOnline,
  }) async {
    final response = await _apiService.getAdvisors(
      category: category,
      search: search,
      onlyOnline: onlyOnline,
    );
    return response.data ?? [];
  }

  Future<Advisor?> getAdvisorById(String id) async {
    final response = await _apiService.getAdvisorById(id);
    return response.data;
  }

  Future<List<Map<String, dynamic>>> getMyConsultations() async {
    final response = await _apiService.getMyConsultations();
    return response.data ?? [];
  }
}
