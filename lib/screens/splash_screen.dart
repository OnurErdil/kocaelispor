import 'package:flutter/material.dart';
import 'dart:async';
import 'anasayfa.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 3 saniye sonra HomePage'e yönlendirme
    Timer(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => Anasayfa()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF00913C), // Kocaelispor yeşili
      body: Center(
        child: Image.asset(
          'assets/images/kocaelispor_logo.png',
          width: 180,
          height: 180,
        ),
      ),
    );
  }
}
