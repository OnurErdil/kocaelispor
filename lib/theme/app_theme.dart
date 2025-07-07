// lib/theme/app_theme.dart - DÜZELTİLMİŞ VERSİYON
import 'package:flutter/material.dart';

class AppTheme {
  // Kocaelispor renkleri
  static const Color primaryGreen = Color(0xFF00913C);
  static const Color primaryDark = Color(0xFF006B2F);
  static const Color background = Color(0xFF0F0F0F);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color cardColor = Color(0xFF2D2D2D);

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryGreen,
    scaffoldBackgroundColor: background,

    colorScheme: const ColorScheme.dark(
      primary: primaryGreen,
      secondary: primaryDark,
      surface: surface,
      background: background,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),

    // ✅ DÜZELTME: CardTheme yerine CardThemeData
    cardTheme: const CardThemeData(
      color: cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryGreen, width: 2),
      ),
    ),

    // ✅ EK: Diğer yararlı tema ayarları
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1A1A1A),
      selectedItemColor: primaryGreen,
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: primaryGreen,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}