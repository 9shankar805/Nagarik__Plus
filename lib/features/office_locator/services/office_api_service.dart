import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/office_model.dart';

class OfficeApiService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<List<OfficeModel>>> getOffices({
    String? category,
    String? search,
    double? latitude,
    double? longitude,
  }) async {
    final params = <String, dynamic>{};
    if (category != null && category.isNotEmpty && category != 'All' && category != 'सबै') {
      params['category'] = category;
    }
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (latitude != null) params['lat'] = latitude;
    if (longitude != null) params['lng'] = longitude;

    return await _apiClient.get(
      '/offices',
      queryParameters: params,
      fromJsonT: (json) {
        final rawList = (json is Map && json['data'] != null)
            ? (json['data'] is Map && json['data']['data'] != null
                ? json['data']['data'] as List
                : (json['data'] is List ? json['data'] as List : []))
            : (json is List ? json : []);
        return rawList
            .map((item) => OfficeModel.fromJson(item as Map<String, dynamic>))
            .toList();
      },
    );
  }
}
