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

// Providers
import 'providers/tab_provider.dart';

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
    return ChangeNotifierProvider(
      create: (_) => TabProvider(),
      child: MaterialApp(
        title: 'Kocaelispor 1966',
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
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
    // 2 saniye splash screen göster
    await Future.delayed(const Duration(seconds: 2));

    try {
      // SharedPreferences kontrol et
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

      if (mounted) {
        if (!onboardingCompleted) {
          // İlk kez açılıyor - onboarding göster
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          );
        } else {
          // Onboarding tamamlanmış - auth kontrol et
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            // Giriş yapmış - ana ekrana git
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()),
            );
          } else {
            // Giriş yapmamış - login'e git
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          }
        }
      }
    } catch (e) {
      print("❌ Başlatma hatası: $e");
      // Hata durumunda login'e yönlendir
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
            // Kocaelispor logosu
            Icon(
              Icons.sports_soccer,
              size: 100,
              color: Colors.white,
            ),
            SizedBox(height: 20),

            // Uygulama adı
            Text(
              'Kocaelispor 1966',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 8),

            // Alt başlık
            Text(
              'Taraftar Uygulaması',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 40),

            // Yükleniyor animasyonu
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),
            SizedBox(height: 20),

            // Yükleniyor metni
            Text(
              'Yükleniyor...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Auth Checker - Firebase auth durumunu kontrol eder
class AuthChecker extends StatelessWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Firebase bağlantısı bekleniyor
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // Hata durumu
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: AppTheme.primaryGreen,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Bağlantı Hatası',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Hata: ${snapshot.error}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {
                      // Uygulamayı yeniden başlat
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const MyApp()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryGreen,
                    ),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
          );
        }

        // Kullanıcı durumuna göre yönlendirme
        if (snapshot.hasData && snapshot.data != null) {
          // Kullanıcı giriş yapmış
          return const MainScreen();
        } else {
          // Kullanıcı giriş yapmamış
          return const LoginPage();
        }
      },
    );
  }
}