// lib/provider/language_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'language_code';

  Locale _currentLocale = const Locale('tr', 'TR');
  late SharedPreferences _prefs;

  Locale get currentLocale => _currentLocale;

  // Dil başlatma
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadLanguage();
    print("🌍 Language Provider başlatıldı - Mevcut dil: ${_currentLocale.languageCode}");
  }

  // Kaydedilmiş dili yükle
  Future<void> _loadLanguage() async {
    final savedLanguage = _prefs.getString(_languageKey);
    if (savedLanguage != null) {
      switch (savedLanguage) {
        case 'tr':
          _currentLocale = const Locale('tr', 'TR');
          break;
        case 'en':
          _currentLocale = const Locale('en', 'US');
          break;
        default:
          _currentLocale = const Locale('tr', 'TR');
      }
    }
    notifyListeners();
  }

  // Dili değiştir
  Future<void> setLanguage(String languageCode) async {
    switch (languageCode) {
      case 'tr':
        _currentLocale = const Locale('tr', 'TR');
        break;
      case 'en':
        _currentLocale = const Locale('en', 'US');
        break;
      default:
        _currentLocale = const Locale('tr', 'TR');
    }

    await _prefs.setString(_languageKey, languageCode);
    notifyListeners();
    print("🌍 Dil değiştirildi: $languageCode");
  }

  // Dili değiştir (toggle)
  Future<void> toggleLanguage() async {
    final newLanguage = _currentLocale.languageCode == 'tr' ? 'en' : 'tr';
    await setLanguage(newLanguage);
  }

  // Türkçe mi kontrol et
  bool get isTurkish => _currentLocale.languageCode == 'tr';

  // Dil bayrağı
  String get languageFlag => isTurkish ? '🇹🇷' : '🇺🇸';

  // Dil adı
  String get languageName => isTurkish ? 'Türkçe' : 'English';
}