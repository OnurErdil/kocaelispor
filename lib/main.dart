// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'screens/main_screen.dart';
import 'screens/login_page.dart';
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'services/analytics_service.dart';
import 'provider/theme_provider.dart';  // ✅ Doğru path
import 'provider/language_provider.dart';  // ✅ Doğru path
import 'l10n/app_localizations.dart';  // ✅ Manuel import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // System UI optimizations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // System UI style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Servisleri başlat
  try {
    await Future.wait([
      AnalyticsService.initialize(),
      NotificationService.initialize(), // ✅ Artık çalışacak
    ]);
    print("✅ Tüm servisler başarıyla başlatıldı!");
  } catch (e) {
    print("⚠️ Bazı servisler başlatılamadı: $e");
    // Uygulama yine de devam etsin
  }

  // Provider'ları başlat
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  final languageProvider = LanguageProvider();
  await languageProvider.initialize();

  runApp(MyApp(
    themeProvider: themeProvider,
    languageProvider: languageProvider,
  ));
}

class MyApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  final LanguageProvider languageProvider;

  const MyApp({
    super.key,
    required this.themeProvider,
    required this.languageProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          return MaterialApp(
            title: 'Kocaelispor 1966',
            debugShowCheckedModeBanner: false,

            // ✅ Localization ayarları
            localizationsDelegates: const [
              AppLocalizations.delegate,  // ✅ Bizim localizations
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('tr', 'TR'),  // Türkçe
              Locale('en', 'US'),  // İngilizce
            ],
            locale: languageProvider.currentLocale,  // ✅ Dinamik dil

            // ✅ Tema ayarları
            themeMode: themeProvider.flutterThemeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,

            // ✅ Başlangıç ekranı
            home: const AuthWrapper(),

            // ✅ Navigator observer (analytics için)
            navigatorObservers: [
              AnalyticsService.observer,
            ],
          );
        },
      ),
    );
  }
}

// Auth kontrol wrapper'ı
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading durumu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Kullanıcı giriş yapmış mı kontrol et
        if (snapshot.hasData && snapshot.data != null) {
          return const MainScreen();  // Ana ekran
        } else {
          return const LoginPage();   // Giriş ekranı
        }
      },
    );
  }
}