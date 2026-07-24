
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/citizen_service.dart';

class CitizenServiceApi {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<List<CitizenService>>> getServices() async {
    return await _apiClient.get(
      '/services',
      fromJsonT: (json) => (json as List)
          .map((item) => CitizenService.fromJson(item))
          .toList(),
    );
  }

  Future<ApiResponse<CitizenService>> getService(String slug) async {
    return await _apiClient.get(
      '/services/$slug',
      fromJsonT: (json) => CitizenService.fromJson(json),
    );
  }

  Future<ApiResponse<List<ServiceOffice>>> getServiceOffices(
    String slug,
  ) async {
    return await _apiClient.get(
      '/services/$slug/offices',
      fromJsonT: (json) => (json as List)
          .map((item) => ServiceOffice.fromJson(item))
          .toList(),
    );
  }
}
