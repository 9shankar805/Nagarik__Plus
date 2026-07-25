
import 'package:nagarik_plus/core/network/api_client.dart';
import '../models/banner_model.dart';
import '../models/social_service_model.dart';
import '../models/vital_event_model.dart';

class HomeApiService {
  final ApiClient _apiClient;

  HomeApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<BannerModel>> getBanners() async {
    final response = await _apiClient.get('banners');
    if (response.success && response.data != null) {
      return (response.data as List)
          .map((json) => BannerModel.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<List<SocialServiceModel>> getSocialServices() async {
    final response = await _apiClient.get('social-services');
    if (response.success && response.data != null) {
      return (response.data as List)
          .map((json) => SocialServiceModel.fromJson(json))
          .toList();
    }
    return [];
  }

  Future<List<VitalEventModel>> getVitalEvents() async {
    final response = await _apiClient.get('vital-events');
    if (response.success && response.data != null) {
      return (response.data as List)
          .map((json) => VitalEventModel.fromJson(json))
          .toList();
    }
    return [];
  }
}

