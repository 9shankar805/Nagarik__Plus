
import 'package:nagarik_plus/core/network/api_client.dart';
import 'package:nagarik_plus/core/network/api_response.dart';
import '../models/banner_model.dart';
import '../models/social_service_model.dart';
import '../models/vital_event_model.dart';

class HomeApiService {
  final ApiClient _apiClient;

  HomeApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future&lt;List&lt;BannerModel&gt;&gt; getBanners() async {
    final response = await _apiClient.get('banners');
    if (response.success &amp;&amp; response.data != null) {
      return (response.data as List)
          .map((json) =&gt; BannerModel.fromJson(json))
          .toList();
    }
    return [];
  }

  Future&lt;List&lt;SocialServiceModel&gt;&gt; getSocialServices() async {
    final response = await _apiClient.get('social-services');
    if (response.success &amp;&amp; response.data != null) {
      return (response.data as List)
          .map((json) =&gt; SocialServiceModel.fromJson(json))
          .toList();
    }
    return [];
  }

  Future&lt;List&lt;VitalEventModel&gt;&gt; getVitalEvents() async {
    final response = await _apiClient.get('vital-events');
    if (response.success &amp;&amp; response.data != null) {
      return (response.data as List)
          .map((json) =&gt; VitalEventModel.fromJson(json))
          .toList();
    }
    return [];
  }
}

