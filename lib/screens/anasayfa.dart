// lib/screens/anasayfa.dart - 6 BUTONLU BASİT VERSİYON
import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import 'kadro_sayfasi.dart';
import 'forum_sayfasi.dart';
import 'puan_durumu_sayfasi.dart';
import 'istatistikler_sayfasi.dart';
import 'haberler_sayfasi.dart';
import 'galeri_sayfasi.dart'; // ✅ YENİ EKLEME

class Anasayfa extends StatefulWidget {
  const Anasayfa({super.key});

  @override
  State<Anasayfa> createState() => _AnasayfaState();
}

class _AnasayfaState extends State<Anasayfa> {
  @override
  void initState() {
    super.initState();
    // Sayfa yüklendiğinde hoş geldin bildirimi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.showTeamNotification(
        context,
        title: 'Hoş Geldiniz!',
        message: 'Kocaelispor taraftar uygulamasına hoş geldiniz! 🔥',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Ana Sayfa",
        showBackButton: false,
      ),
      body: SingleChildScrollView(
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

            // 1. SIRA - 2 BUTON
            Row(
              children: [
                Expanded(
                  child: _menuButonu(
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
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _menuButonu(
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
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 2. SIRA - 2 BUTON
            Row(
              children: [
                Expanded(
                  child: _menuButonu(
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
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _menuButonu(
                    icon: Icons.analytics,
                    title: 'İstatistikler',
                    subtitle: 'Taraftar verileri',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const IstatistiklerSayfasi()),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 3. SIRA - 2 BUTON
            Row(
              children: [
                Expanded(
                  child: _menuButonu(
                    icon: Icons.newspaper,
                    title: 'Haberler',
                    subtitle: 'Takım haberleri',
                    color: Colors.red,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HaberlerSayfasi()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _menuButonu(
                    icon: Icons.photo_library,
                    title: 'Galeri',
                    subtitle: 'Fotoğraf galerisi',
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GaleriSayfasi()),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 4. SIRA - 1 BUTON (ortalanmış)
            Row(
              children: [
                Expanded(
                  child: _menuButonu(
                    icon: Icons.more_horiz,
                    title: 'Yakında',
                    subtitle: 'Yeni özellikler...',
                    color: Colors.grey,
                    onTap: () {
                      NotificationService.showWarningNotification(
                        context,
                        message: 'Yeni özellikler yakında!',
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(child: SizedBox()), // Boş alan
              ],
            ),

            const SizedBox(height: 24),

            // Test Bildirimleri Butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showTestNotifications(context),
                icon: const Icon(Icons.notifications_active),
                label: const Text('Test Bildirimleri'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Test bildirimleri fonksiyonu
  void _showTestNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Bildirimleri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  NotificationService.showSuccessNotification(
                    context,
                    message: 'Bu bir başarı bildirimi!',
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Başarı Bildirimi'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  NotificationService.showErrorNotification(
                    context,
                    message: 'Bu bir hata bildirimi!',
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Hata Bildirimi'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  NotificationService.showForumMessageNotification(
                    context,
                    senderName: 'Test Kullanıcı',
                    message: 'Bu bir forum mesaj bildirimi!',
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Forum Bildirimi'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  NotificationService.showTeamNotification(
                    context,
                    title: 'Maç Sonucu!',
                    message: 'Kocaelispor 3-1 kazandı! ⚽',
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
                child: const Text('Takım Bildirimi'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _menuButonu({
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
        child: Container(
          height: 120,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 36,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}