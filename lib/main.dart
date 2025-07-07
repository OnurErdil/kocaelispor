// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/main_screen.dart';
import 'screens/login_page.dart';
import 'theme/app_theme.dart'; // ✅ YENİ TEMA

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
    return MaterialApp(
      title: 'Kocaelispor Fan App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme, // ✅ TUTARLı TEMA
      home: const AuthWrapper(),
    );
  }
}

// AuthWrapper aynı kalır...
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      return const MainScreen(); // Oturum varsa direkt MainScreen
    } else {
      return const LoginPage(); // 💚 DOĞRU // const yok!

    }
  }
}
