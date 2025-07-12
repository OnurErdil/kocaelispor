// lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeMode { light, dark, system }

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  late SharedPreferences _prefs;

  ThemeMode get themeMode => _themeMode;

  // Tema başlatma
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadTheme();
    print("🎨 Theme Provider başlatıldı - Mevcut tema: $_themeMode");
  }

  // Kaydedilmiş temayı yükle
  Future<void> _loadTheme() async {
    final savedTheme = _prefs.getString(_themeKey);
    if (savedTheme != null) {
      switch (savedTheme) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'system':
          _themeMode = ThemeMode.system;
          break;
        default:
          _themeMode = ThemeMode.system;
      }
    }
    notifyListeners();
  }

  // Temayı değiştir
  Future<void> setThemeMode(ThemeMode themeMode) async {
    _themeMode = themeMode;
    await _prefs.setString(_themeKey, themeMode.toString().split('.').last);
    notifyListeners();
    print("🎨 Tema değiştirildi: $themeMode");
  }

  // Sistem temasını takip et
  bool get isSystemMode => _themeMode == ThemeMode.system;

  // Mevcut temayı kontrol et (sistem teması için)
  bool isDarkMode(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.light:
        return false;
      case ThemeMode.dark:
        return true;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
  }

  // Tema simgesi al
  IconData get themeIcon {
    switch (_themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }

  // Tema açıklaması al
  String get themeDescription {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Açık Tema';
      case ThemeMode.dark:
        return 'Koyu Tema';
      case ThemeMode.system:
        return 'Sistem Teması';
    }
  }

  // Sonraki temaya geç (hızlı değiştirme için)
  Future<void> toggleTheme() async {
    switch (_themeMode) {
      case ThemeMode.light:
        await setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await setThemeMode(ThemeMode.system);
        break;
      case ThemeMode.system:
        await setThemeMode(ThemeMode.light);
        break;
    }
  }

  // Flutter ThemeMode'a dönüştür
  MaterialApp.of get flutterThemeMode {
    switch (_themeMode) {
      case ThemeMode.light:
        return ThemeMode.light as MaterialApp.of;
      case ThemeMode.dark:
        return ThemeMode.dark as MaterialApp.of;
      case ThemeMode.system:
        return ThemeMode.system as MaterialApp.of;
    }
  }
}