
import '../models/banner_model.dart';
import '../models/social_service_model.dart';
import '../models/vital_event_model.dart';
import '../services/home_api_service.dart';

class HomeRepository {
  final HomeApiService _apiService;

  HomeRepository({HomeApiService? apiService})
      : _apiService = apiService ?? HomeApiService();

  Future&lt;List&lt;BannerModel&gt;&gt; getBanners() async {
    return await _apiService.getBanners();
  }

  Future&lt;List&lt;SocialServiceModel&gt;&gt; getSocialServices() async {
    return await _apiService.getSocialServices();
  }

  Future&lt;List&lt;VitalEventModel&gt;&gt; getVitalEvents() async {
    return await _apiService.getVitalEvents();
  }
}

