
import 'package:flutter/foundation.dart';
import '../models/reminder_model.dart';
import '../repositories/reminders_repository.dart';

enum RemindersStatus { initial, loading, loaded, error }

class RemindersProvider extends ChangeNotifier {
  final RemindersRepository _repository;

  RemindersStatus _status = RemindersStatus.initial;
  List<Reminder> _reminders = [];
  String? _errorMessage;

  RemindersStatus get status => _status;
  List<Reminder> get reminders => _reminders;
  String? get errorMessage => _errorMessage;

  RemindersProvider({RemindersRepository? repository})
      : _repository = repository ?? RemindersRepository();

  Future<void> loadReminders({bool forceRefresh = false}) async {
    _status = RemindersStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      _reminders = await _repository.getReminders(forceRefresh: forceRefresh);
      _status = RemindersStatus.loaded;
    } catch (e) {
      _errorMessage = e.toString();
      _status = RemindersStatus.error;
    }
    notifyListeners();
  }

  Future<void> addReminder(Map<String, dynamic> data) async {
    try {
      final reminder = await _repository.createReminder(data);
      _reminders.add(reminder);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> updateRem(int id, Map<String, dynamic> data) async {
    try {
      final updatedRem = await _repository.updateReminder(id, data);
      final index = _reminders.indexWhere((r) => r.id == id);
      if (index != -1) {
        _reminders[index] = updatedRem;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteRem(int id) async {
    try {
      await _repository.deleteReminder(id);
      _reminders.removeWhere((r) => r.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
