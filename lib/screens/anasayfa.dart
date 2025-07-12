// lib/screens/anasayfa.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/analytics_wrapper.dart';  // ✅ Import eklendi
import '../services/analytics_service.dart';  // ✅ Import eklendi
import '../theme/app_theme.dart';
import 'kadro_sayfasi.dart';
import 'takvim_sayfasi.dart';
import 'puan_durumu_sayfasi.dart';
import 'news_page.dart';

class Anasayfa extends StatefulWidget {
  const Anasayfa({super.key});

  @override
  State<Anasayfa> createState() => _AnasayfaState();
}

class _AnasayfaState extends State<Anasayfa> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnalyticsWrapper(
      screenName: 'home_screen',
      onScreenView: () => AnalyticsService.logAppOpen(),
      child: Scaffold(
        appBar: const CustomAppBar(
          title: "Ana Sayfa",
          showBackButton: false,
          showThemeToggle: true, // ✅ Tema butonunu göster
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {});
            await Future.delayed(const Duration(seconds: 1));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  // Hoş geldin kartı
                  _buildWelcomeCard(),

                  // Son maç ve yaklaşan maç
                  _buildMatchSection(),

                  // Hızlı erişim menüsü
                  _buildQuickAccessMenu(),

                  // Son haberler
                  _buildNewsSection(),
                ],
              ),
            ),
          ),
        ),
      ), // ✅ Bu parantez eksikti!
    );
  }

  // Hoş geldin kartı
  Widget _buildWelcomeCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.primaryGreen.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Merhaba Taraftar!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kocaelispor\'un en güncel haberlerini takip et',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.sports_soccer,
            color: Colors.white,
            size: 48,
          ),
        ],
      ),
    );
  }

  // Son maç bölümü
  Widget _buildMatchSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Maçlar',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildMatchCard('Son Maç', 'Kocaelispor 2-1 Rizespor', true)),
              const SizedBox(width: 12),
              Expanded(child: _buildMatchCard('Sonraki Maç', 'Kocaelispor - Trabzonspor', false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(String title, String match, bool isResult) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              match,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Icon(
              isResult ? Icons.check_circle : Icons.schedule,
              color: isResult ? Colors.green : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  // Hızlı erişim menüsü
  Widget _buildQuickAccessMenu() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hızlı Erişim',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildQuickAccessCard('Kadro', Icons.people, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const KadroSayfasi()));
              }),
              _buildQuickAccessCard('Takvim', Icons.calendar_today, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TakvimSayfasi()));
              }),
              _buildQuickAccessCard('Puan Durumu', Icons.table_chart, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PuanDurumuSayfasi()));
              }),
              _buildQuickAccessCard('Haberler', Icons.article, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsPage()));
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
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
                size: 32,
                color: AppTheme.primaryGreen,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Son haberler bölümü
  Widget _buildNewsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Son Haberler',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewsPage()),
                ),
                child: const Text('Tümünü Gör'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('haberler')
                .orderBy('tarih', descending: true)
                .limit(3)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyNewsCard();
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final haber = doc.data() as Map<String, dynamic>;
                  return _buildNewsItem(haber);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNewsItem(Map<String, dynamic> haber) {
    final tarih = haber['tarih'] as Timestamp?;
    final formattedDate = tarih != null
        ? "${tarih.toDate().day}.${tarih.toDate().month}.${tarih.toDate().year}"
        : 'Tarih yok';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryGreen,
          child: const Icon(Icons.article, color: Colors.white, size: 20),
        ),
        title: Text(
          haber['baslik'] ?? 'Başlık Yok',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(formattedDate),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Haber detayına git
        },
      ),
    );
  }

  Widget _buildEmptyNewsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.article_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Henüz haber bulunmuyor',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}