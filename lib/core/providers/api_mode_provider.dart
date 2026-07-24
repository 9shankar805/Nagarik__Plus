
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiModeProvider extends ChangeNotifier {
  static const String _key = 'api_mode_offline';
  bool _isOffline = false;

  bool get isOffline => _isOffline;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _isOffline = prefs.getBool(_key) ?? false;
    notifyListeners();
  }

  Future<void> setOffline(bool value) async {
    _isOffline = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
    notifyListeners();
  }
}

