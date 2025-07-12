// lib/providers/language_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';

  Locale _currentLocale = const Locale('tr', 'TR'); // Varsayılan Türkçe
  late SharedPreferences _prefs;

  Locale get currentLocale => _currentLocale;

  // Desteklenen diller
  static const List<Locale> supportedLocales = [
    Locale('tr', 'TR'), // Türkçe
    Locale('en', 'US'), // İngilizce
  ];

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
  Future<void> setLanguage(Locale locale) async {
    _currentLocale = locale;
    await _prefs.setString(_languageKey, locale.languageCode);
    notifyListeners();
    print("🌍 Dil değiştirildi: ${locale.languageCode}");
  }

  // Türkçe mi kontrol et
  bool get isTurkish => _currentLocale.languageCode == 'tr';

  // İngilizce mi kontrol et
  bool get isEnglish => _currentLocale.languageCode == 'en';

  // Dil ismi al
  String get languageName {
    switch (_currentLocale.languageCode) {
      case 'tr':
        return 'Türkçe';
      case 'en':
        return 'English';
      default:
        return 'Türkçe';
    }
  }

  // Dil simgesi al
  String get languageFlag {
    switch (_currentLocale.languageCode) {
      case 'tr':
        return '🇹🇷';
      case 'en':
        return '🇺🇸';
      default:
        return '🇹🇷';
    }
  }

  // Dil ikonu al
  IconData get languageIcon {
    switch (_currentLocale.languageCode) {
      case 'tr':
        return Icons.language;
      case 'en':
        return Icons.translate;
      default:
        return Icons.language;
    }
  }

  // Sonraki dile geç (hızlı değiştirme için)
  Future<void> toggleLanguage() async {
    if (_currentLocale.languageCode == 'tr') {
      await setLanguage(const Locale('en', 'US'));
    } else {
      await setLanguage(const Locale('tr', 'TR'));
    }
  }

  // Dil koduna göre Locale al
  static Locale getLocaleFromCode(String languageCode) {
    switch (languageCode) {
      case 'tr':
        return const Locale('tr', 'TR');
      case 'en':
        return const Locale('en', 'US');
      default:
        return const Locale('tr', 'TR');
    }
  }

  // Mevcut dilin tüm bilgilerini al
  Map<String, dynamic> get currentLanguageInfo {
    return {
      'code': _currentLocale.languageCode,
      'name': languageName,
      'flag': languageFlag,
      'locale': _currentLocale,
    };
  }
}