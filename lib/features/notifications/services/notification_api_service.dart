
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/notification_item.dart';
import '../models/notification_preferences.dart';

class NotificationApiService {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<List<NotificationItem>>> getNotifications() async {
    return await _apiClient.get(
      '/notifications',
      fromJsonT: (json) => (json as List)
          .map((item) => NotificationItem.fromJson(item))
          .toList(),
    );
  }

  Future<ApiResponse<NotificationPreferences>> getPreferences() async {
    return await _apiClient.get(
      '/notifications/preferences',
      fromJsonT: (json) => NotificationPreferences.fromJson(json),
    );
  }

  Future<ApiResponse<NotificationPreferences>> updatePreferences(
    NotificationPreferences preferences,
  ) async {
    return await _apiClient.put(
      '/notifications/preferences',
      data: preferences.toJson(),
      fromJsonT: (json) => NotificationPreferences.fromJson(json),
    );
  }

  Future<ApiResponse<void>> registerDeviceToken(String token) async {
    return await _apiClient.post(
      '/notifications/device-token',
      data: {'token': token},
    );
  }

  Future<ApiResponse<void>> markAsRead(String id) async {
    return await _apiClient.post(
      '/notifications/$id/read',
    );
  }

  Future<ApiResponse<void>> markAllAsRead() async {
    return await _apiClient.post(
      '/notifications/read-all',
    );
  }
}
