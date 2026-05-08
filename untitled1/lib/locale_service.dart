import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported locales for the app.
class AppLocales {
  static const Locale english = Locale('en');
  static const Locale tagalog = Locale('tl');

  static const List<Locale> supported = [english, tagalog];

  static const Locale fallback = english;

  static String displayName(Locale locale) {
    switch (locale.languageCode) {
      case 'tl':
        return 'Tagalog (Filipino)';
      case 'en':
      default:
        return 'English';
    }
  }

  static String nativeName(Locale locale) {
    switch (locale.languageCode) {
      case 'tl':
        return 'Tagalog';
      case 'en':
      default:
        return 'English';
    }
  }
}

/// Persists and provides the user's selected locale.
class LocaleService extends ChangeNotifier {
  static const String _prefKey = 'app_locale';
  static LocaleService? _instance;

  Locale _locale = AppLocales.fallback;

  LocaleService._();

  static LocaleService get instance {
    _instance ??= LocaleService._();
    return _instance!;
  }

  Locale get locale => _locale;

  /// Load saved locale from preferences.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefKey);
    if (code != null) {
      final saved = Locale(code);
      if (AppLocales.supported.contains(saved)) {
        _locale = saved;
        notifyListeners();
      }
    }
  }

  /// Set and persist a new locale.
  Future<void> setLocale(Locale newLocale) async {
    if (!AppLocales.supported.contains(newLocale)) return;
    if (_locale == newLocale) return;

    _locale = newLocale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, newLocale.languageCode);
  }

  /// Convenience toggle between English and Tagalog.
  Future<void> toggleLocale() async {
    final next = _locale == AppLocales.english
        ? AppLocales.tagalog
        : AppLocales.english;
    await setLocale(next);
  }
}
