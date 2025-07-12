// lib/provider/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ Flutter'ın ThemeMode'unu kullanıyoruz, kendi enum'umuzu kaldırdık
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system; // ✅ Flutter'ın ThemeMode'unu kullan
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
    // ✅ enum'un string değerini daha güvenli şekilde al
    final themeString = themeMode.name; // .name kullanarak daha temiz
    await _prefs.setString(_themeKey, themeString);
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

  // ✅ Flutter ThemeMode'unu direkt döndür (gereksiz dönüştürme yok)
  ThemeMode get flutterThemeMode => _themeMode;

  // Tema renk paleti (koyu/açık tema için farklı renkler)
  ColorScheme getColorScheme(BuildContext context) {
    final isDark = isDarkMode(context);

    if (isDark) {
      return ColorScheme.dark(
        primary: const Color(0xFF4CAF50), // Kocaelispor yeşili
        secondary: const Color(0xFF81C784),
        surface: const Color(0xFF121212),
        background: const Color(0xFF121212),
        error: Colors.red.shade400,
      );
    } else {
      return ColorScheme.light(
        primary: const Color(0xFF4CAF50), // Kocaelispor yeşili
        secondary: const Color(0xFF66BB6A),
        surface: Colors.white,
        background: const Color(0xFFF5F5F5),
        error: Colors.red.shade600,
      );
    }
  }

  // Tema verilerini export et (settings sayfası için)
  Map<String, dynamic> get themeInfo {
    return {
      'mode': _themeMode.name,
      'description': themeDescription,
      'icon': themeIcon,
      'isSystem': isSystemMode,
    };
  }

  // Tema istatistikleri (analytics için)
  Future<void> logThemeChange() async {
    print("📊 Tema değişikliği: ${_themeMode.name}");
    // Burada analytics servisini çağırabilirsiniz
    // AnalyticsService.logThemeChange(_themeMode.name);
  }
}