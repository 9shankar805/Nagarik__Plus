
import 'package:flutter/foundation.dart';
import '../models/notification_item.dart';
import '../models/notification_preferences.dart';
import '../repositories/notification_repository.dart';

enum NotificationStatus { initial, loading, loaded, error }

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;

  NotificationStatus _status = NotificationStatus.initial;
  List<NotificationItem> _notifications = [];
  NotificationPreferences _preferences = NotificationPreferences(
    news: true,
    documents: true,
    reminders: true,
    services: true,
    ai: true,
  );
  String? _errorMessage;

  NotificationStatus get status => _status;
  List<NotificationItem> get notifications => _notifications;
  NotificationPreferences get preferences => _preferences;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationProvider({NotificationRepository? repository})
      : _repository = repository ?? NotificationRepository();

  Future<void> loadNotifications({bool forceRefresh = false}) async {
    _status = NotificationStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _repository.getNotifications(forceRefresh: forceRefresh);
      _status = NotificationStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = NotificationStatus.error;
    }
    notifyListeners();
  }

  Future<void> loadPreferences({bool forceRefresh = false}) async {
    try {
      _preferences = await _repository.getPreferences(forceRefresh: forceRefresh);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updatePreferences(NotificationPreferences preferences) async {
    try {
      _preferences = await _repository.updatePreferences(preferences);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _repository.markAsRead(id);
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> registerDeviceToken(String token) async {
    try {
      await _repository.registerDeviceToken(token);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
