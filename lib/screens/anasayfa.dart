// lib/screens/anasayfa.dart
import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';
import 'kadro_sayfasi.dart';

class Anasayfa extends StatelessWidget {
  const Anasayfa({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Ana Sayfa",
        showBackButton: false, // Ana sayfada geri butonu yok
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tutarlı card tasarımı
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.sports_soccer,
                      size: 80,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Hoş Geldiniz!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kadro yönetimi için aşağıdaki butona tıklayın',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.people),
                        label: const Text('Kadroya Git'),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const KadroSayfasi()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}