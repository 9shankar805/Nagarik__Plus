
import 'package:hive_flutter/hive_flutter.dart';
import '../services/notification_api_service.dart';
import '../models/notification_item.dart';
import '../models/notification_preferences.dart';

class NotificationRepository {
  final NotificationApiService _apiService;
  final Box<NotificationItem>? _notificationsBox;
  final Box<NotificationPreferences>? _preferencesBox;

  NotificationRepository({
    NotificationApiService? apiService,
    Box<NotificationItem>? notificationsBox,
    Box<NotificationPreferences>? preferencesBox,
  })  : _apiService = apiService ?? NotificationApiService(),
        _notificationsBox = notificationsBox,
        _preferencesBox = preferencesBox;

  Future<List<NotificationItem>> getNotifications({bool forceRefresh = false}) async {
    if (!forceRefresh && _notificationsBox != null && _notificationsBox.isNotEmpty) {
      return _notificationsBox.values.toList();
    }

    try {
      final response = await _apiService.getNotifications();
      final notifications = response.data ?? [];
      if (_notificationsBox != null) {
        await _notificationsBox.clear();
        await _notificationsBox.addAll(notifications);
      }
      return notifications;
    } catch (e) {
      if (_notificationsBox != null && _notificationsBox.isNotEmpty) {
        return _notificationsBox.values.toList();
      }
      rethrow;
    }
  }

  Future<NotificationPreferences> getPreferences({bool forceRefresh = false}) async {
    if (!forceRefresh && _preferencesBox != null && _preferencesBox.isNotEmpty) {
      return _preferencesBox.values.first;
    }

    try {
      final response = await _apiService.getPreferences();
      final preferences = response.data ?? NotificationPreferences(
        news: true,
        documents: true,
        reminders: true,
        services: true,
        ai: true,
      );
      if (_preferencesBox != null) {
        await _preferencesBox.clear();
        await _preferencesBox.add(preferences);
      }
      return preferences;
    } catch (e) {
      if (_preferencesBox != null && _preferencesBox.isNotEmpty) {
        return _preferencesBox.values.first;
      }
      rethrow;
    }
  }

  Future<NotificationPreferences> updatePreferences(
    NotificationPreferences preferences,
  ) async {
    try {
      final response = await _apiService.updatePreferences(preferences);
      final updatedPreferences = response.data ?? preferences;
      if (_preferencesBox != null) {
        await _preferencesBox.clear();
        await _preferencesBox.add(updatedPreferences);
      }
      return updatedPreferences;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> registerDeviceToken(String token) async {
    try {
      await _apiService.registerDeviceToken(token);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _apiService.markAsRead(id);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiService.markAllAsRead();
    } catch (e) {
      rethrow;
    }
  }
}
