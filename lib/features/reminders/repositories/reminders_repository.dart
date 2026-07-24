
import 'package:hive_flutter/hive_flutter.dart';
import '../services/reminders_api_service.dart';
import '../models/reminder_model.dart';

class RemindersRepository {
  final RemindersApiService _apiService;
  final Box<Reminder>? _box;

  RemindersRepository({RemindersApiService? apiService, Box<Reminder>? box})
      : _apiService = apiService ?? RemindersApiService(),
        _box = box;

  Future<List<Reminder>> getReminders({bool forceRefresh = false}) async {
    if (_box != null && !forceRefresh && _box!.isNotEmpty) {
      return _box!.values.toList();
    }

    try {
      final response = await _apiService.getReminders();
      final reminders = response.data ?? [];
      if (_box != null) {
        await _box!.clear();
        await _box!.addAll(reminders);
      }
      return reminders;
    } catch (e) {
      if (_box != null && _box!.isNotEmpty) {
        return _box!.values.toList();
      }
      rethrow;
    }
  }

  Future<Reminder> createReminder(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.createReminder(data);
      if (_box != null) {
        await _box!.add(response.data!);
      }
      return response.data!;
    } catch (e) {
      rethrow;
    }
  }

  Future<Reminder> updateReminder(int id, Map<String, dynamic> data) async {
    try {
      final response = await _apiService.updateReminder(id, data);
      if (_box != null) {
        final index = _box!.values.toList().indexWhere((r) => r.id == id);
        if (index != -1) {
          await _box!.putAt(index, response.data!);
        }
      }
      return response.data!;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteReminder(int id) async {
    try {
      await _apiService.deleteReminder(id);
      if (_box != null) {
        final index = _box!.values.toList().indexWhere((r) => r.id == id);
        if (index != -1) {
          await _box!.deleteAt(index);
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
