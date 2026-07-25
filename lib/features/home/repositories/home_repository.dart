
import '../models/banner_model.dart';
import '../models/social_service_model.dart';
import '../models/vital_event_model.dart';
import '../services/home_api_service.dart';

class HomeRepository {
  final HomeApiService _apiService;

  HomeRepository({HomeApiService? apiService})
      : _apiService = apiService ?? HomeApiService();

  Future<List<BannerModel>> getBanners() async {
    return await _apiService.getBanners();
  }

  Future<List<SocialServiceModel>> getSocialServices() async {
    return await _apiService.getSocialServices();
  }

  Future<List<VitalEventModel>> getVitalEvents() async {
    return await _apiService.getVitalEvents();
  }
}

