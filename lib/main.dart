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
import 'services/performance_service.dart'; // ✅ YENİ EKLEME
import 'services/database_optimizer.dart'; // ✅ YENİ EKLEME
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';
import 'widgets/loading_states.dart'; // ✅ YENİ EKLEME
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ System UI optimizations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // ✅ System UI style
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

  // ✅ Servisleri paralel başlat (performance için)
  await Future.wait([
    PerformanceService.initialize(),
    DatabaseOptimizer.initialize(),
    NotificationService.initialize(),
    AnalyticsService.initialize(),
  ]);

  // Provider'ları başlat
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();

  final languageProvider = LanguageProvider();
  await languageProvider.initialize();

  // ✅ App startup trace'ini tamamla
  await PerformanceService.completeAppStartup();

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
            title: 'Kocaelispor Fan App',
            debugShowCheckedModeBanner: false,

            // ✅ Performance optimizations
            checkerboardRasterCacheImages: false,
            checkerboardOffscreenLayers: false,
            showPerformanceOverlay: false, // Production'da false olmalı

            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _convertThemeMode(themeProvider.themeMode),

            locale: languageProvider.currentLocale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: LanguageProvider.supportedLocales,

            home: const AuthWrapper(),
            navigatorObservers: [
              AnalyticsService.observer,
            ],

            // ✅ Builder wrapper for performance monitoring
            builder: (context, child) {
              // Global error boundary
              return _AppErrorBoundary(child: child ?? const SizedBox());
            },
          );
        },
      ),
    );
  }

  ThemeMode _convertThemeMode(providers.ThemeMode providerThemeMode) {
    switch (providerThemeMode) {
      case providers.ThemeMode.light:
        return ThemeMode.light;
      case providers.ThemeMode.dark:
        return ThemeMode.dark;
      case providers.ThemeMode.system:
        return ThemeMode.system;
    }
  }
}

import 'providers/theme_provider.dart' as providers;

// ✅ Global error boundary
class _AppErrorBoundary extends StatelessWidget {
  final Widget child;

  const _AppErrorBoundary({required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

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
            body: AppLoadingWidget(
              message: "Kocaelispor Fan App Yükleniyor...",
              size: 80,
            ),
          );
        }

        // Hata durumu
        if (snapshot.hasError) {
          return Scaffold(
            body: AppErrorWidget(
              message: "Bağlantı hatası oluştu. Lütfen tekrar deneyin.",
              onRetry: () {
                // Auth stream'i yeniden başlat
                FirebaseAuth.instance.authStateChanges();
              },
            ),
          );
        }

        // Kullanıcı durumuna göre yönlendirme
        if (snapshot.hasData && snapshot.data != null) {
          AnalyticsService.setUserId(snapshot.data!.uid);
          return const MainScreen();
        } else {
          return const LoginPage();
        }
      },
    );
  }
}