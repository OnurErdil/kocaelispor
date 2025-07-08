// lib/screens/anasayfa.dart - GÜNCELLENMİŞ
import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';
import 'kadro_sayfasi.dart';
import 'forum_sayfasi.dart'; // ✅ YENİ EKLEME
import 'puan_durumu_sayfasi.dart'; // ✅ YENİ EKLEME

class Anasayfa extends StatelessWidget {
  const Anasayfa({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Ana Sayfa",
        showBackButton: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Hoş geldin kartı
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
                      'Kocaelispor 1966',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Taraftar Uygulamasına Hoş Geldiniz',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Menü butonları
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  // Kadro sayfası
                  _menuButonu(
                    context,
                    icon: Icons.people,
                    title: 'Takım Kadrosu',
                    subtitle: 'Oyuncuları görüntüle',
                    color: AppTheme.primaryGreen,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const KadroSayfasi()),
                      );
                    },
                  ),

                  // Puan durumu
                  _menuButonu(
                    context,
                    icon: Icons.emoji_events,
                    title: 'Puan Durumu',
                    subtitle: 'Lig sıralaması',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PuanDurumuSayfasi()),
                      );
                    },
                  ),

                  // Forum sayfası - YENİ!
                  _menuButonu(
                    context,
                    icon: Icons.forum,
                    title: 'Taraftar Forumu',
                    subtitle: 'Diğer taraftarlarla sohbet et',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ForumSayfasi()),
                      );
                    },
                  ),

                  // Yakında gelecek özellik
                  _menuButonu(
                    context,
                    icon: Icons.newspaper,
                    title: 'Haberler',
                    subtitle: 'Yakında...',
                    color: Colors.grey,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Bu özellik yakında gelecek!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuButonu(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}