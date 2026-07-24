import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kLocalePreferenceKey = 'app_locale';
const List<String> kSupportedLocaleCodes = ['en', 'ne'];
const String kDefaultLocaleCode = 'ne';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('ne');

  Locale get locale => _locale;

  /// Load persisted locale on app startup — called before runApp.
  /// Does NOT call notifyListeners (no widget tree yet).
  Future<void> loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(kLocalePreferenceKey);
      if (savedCode != null && kSupportedLocaleCodes.contains(savedCode)) {
        _locale = Locale(savedCode);
      } else {
        _locale = const Locale(kDefaultLocaleCode);
      }
    } catch (_) {
      _locale = const Locale(kDefaultLocaleCode);
    }
  }

  /// Switch locale, persist it, and notify listeners.
  Future<void> setLocale(Locale locale) async {
    if (!kSupportedLocaleCodes.contains(locale.languageCode)) return;
    if (_locale == locale) return; // no-op to avoid redundant rebuild

    _locale = locale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kLocalePreferenceKey, locale.languageCode);
    } catch (_) {
      // Persist failed — in-memory locale is still updated, session works fine
    }
  }

  /// Reset to default Nepali locale and remove persisted preference.
  Future<void> resetToDefault() async {
    _locale = const Locale(kDefaultLocaleCode);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(kLocalePreferenceKey);
    } catch (_) {}
  }
}
