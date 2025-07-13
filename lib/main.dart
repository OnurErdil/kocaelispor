// lib/main.dart - TAM VE ÇALIŞIR KOD
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Firebase options
import 'firebase_options.dart';

// Screens
import 'screens/main_screen.dart';
import 'screens/login_page.dart';
import 'screens/onboarding_screen.dart';

// Theme
import 'theme/app_theme.dart';

// Providers - TÜM PROVIDER'LARI İÇE AKTAR
import 'providers/tab_provider.dart';
import 'provider/theme_provider.dart';  // ✅ Tema provider'ı ekledik
import 'provider/language_provider.dart';  // ✅ Dil provider'ı ekledik

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Firebase'i başlat
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("✅ Firebase başlatıldı!");
  } catch (e) {
    print("❌ Firebase hatası: $e");
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ ÇOK ÖNEMLİ: Tüm provider'ları burada tanımla
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TabProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return Consumer<LanguageProvider>(
            builder: (context, languageProvider, child) {
              return MaterialApp(
                title: 'Kocaelispor 1966',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeProvider.themeMode,  // ✅ Tema provider'dan al
                locale: languageProvider.currentLocale,  // ✅ Dil provider'dan al
                home: const SplashScreen(),
                debugShowCheckedModeBanner: false,
              );
            },
          );
        },
      ),
    );
  }
}

// Splash Screen - Yükleme ekranı
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // ✅ Provider'ları başlat
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    // Provider'ları başlat
    await themeProvider.initialize();
    await languageProvider.initialize();

    // 2 saniye splash screen göster
    await Future.delayed(const Duration(seconds: 2));

    try {
      // SharedPreferences kontrol et
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

      if (mounted) {
        if (onboardingCompleted) {
          // Kullanıcı durumunu kontrol et
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            // Kullanıcı giriş yapmış - ana ekrana git
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          } else {
            // Kullanıcı giriş yapmamış - login ekranına git
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
        } else {
          // İlk kez açılıyor - onboarding ekranına git
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        }
      }
    } catch (e) {
      print("❌ Initialization hatası: $e");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryGreen,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Icon(
              Icons.sports_soccer,
              size: 100,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            Text(
              'Kocaelispor 1966',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}