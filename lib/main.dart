// lib/main.dart - THEME SERVİSİ İLE GÜNCELLENMİŞ
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart'; // ✅ YENİ EKLEME
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'services/theme_service.dart'; // ✅ YENİ EKLEME

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeService(),
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'Kocaelispor Fan App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme, // ✅ AÇIK TEMA
            darkTheme: AppTheme.darkTheme, // ✅ KOYU TEMA
            themeMode: themeService.themeMode, // ✅ DİNAMİK TEMA
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}