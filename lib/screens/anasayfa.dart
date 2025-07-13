// lib/screens/anasayfa.dart - Admin Kontrollü Versiyon
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/analytics_wrapper.dart';
import '../services/analytics_service.dart';
import '../services/admin_service.dart';
import '../theme/app_theme.dart';
import 'kadro_sayfasi.dart';
import 'takvim_sayfasi.dart';
import 'puan_durumu_sayfasi.dart';
import 'news_page.dart';
import 'admin_panel_screen.dart';

class Anasayfa extends StatefulWidget {
  const Anasayfa({super.key});

  @override
  State<Anasayfa> createState() => _AnasayfaState();
}

class _AnasayfaState extends State<Anasayfa> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Admin kontrolü için
  bool _isAdmin = false;
  bool _isCheckingAdmin = true;

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
    _checkAdminStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Admin durumunu kontrol et
  Future<void> _checkAdminStatus() async {
    try {
      final adminStatus = await AdminService.isCurrentUserAdmin();
      setState(() {
        _isAdmin = adminStatus;
        _isCheckingAdmin = false;
      });
    } catch (e) {
      setState(() {
        _isAdmin = false;
        _isCheckingAdmin = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnalyticsWrapper(
      screenName: 'home_screen',
      onScreenView: () => AnalyticsService.logAppOpen(),
      child: Scaffold(
        appBar: CustomAppBar(
          title: "Ana Sayfa",
          showBackButton: false,
          showThemeToggle: true,
          // Admin için özel eylemler
          actions: _isAdmin && !_isCheckingAdmin ? [
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
              ),
              icon: Icon(
                Icons.admin_panel_settings,
                color: Colors.orange.shade600,
              ),
              tooltip: 'Admin Paneli',
            ),
          ] : null,
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
                  // Admin kontrol durumu bilgisi
                  if (_isCheckingAdmin)
                    Container(
                      color: Colors.orange.shade50,
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange.shade600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Yetki kontrol ediliyor...',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Admin için özel bilgi çubuğu
                  if (!_isCheckingAdmin && _isAdmin)
                    Container(
                      color: Colors.green.shade50,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.admin_panel_settings,
                              color: Colors.green.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Yönetici Modu Aktif',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'İçerikleri düzenleyebilir ve yönetebilirsiniz',
                                  style: TextStyle(
                                    color: Colors.green.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                            ),
                            child: Text(
                              'Admin Panel',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Hoş geldin kartı
                  _buildWelcomeCard(),

                  // Son maç ve yaklaşan maç
                  _buildMatchSection(),

                  // Hızlı erişim menüsü (admin için özel)
                  _buildQuickAccessMenu(),

                  // Son haberler
                  _buildNewsSection(),

                  // Admin için özel yönetim paneli
                  if (!_isCheckingAdmin && _isAdmin) _buildAdminQuickActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Hoş geldin kartı
  Widget _buildWelcomeCard() {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@')[0] ?? 'Taraftar';

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, Color(0xFF006D2C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
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
                Text(
                  'Hoş geldin,',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isAdmin ? '🔧 Yönetici Paneline Erişim Var' : '⚽ Kocaelispor\'a Hoş Geldin!',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.sports_soccer,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  // Son maçlar bölümü
  Widget _buildMatchSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Son Maçlar',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Son maç kartı (örnek)
          _buildMatchCard(
            'Kocaelispor',
            'Bursaspor',
            '2-1',
            DateTime.now().subtract(const Duration(days: 3)),
            true,
          ),
          const SizedBox(height: 8),

          // Yaklaşan maç kartı (örnek)
          _buildMatchCard(
            'Kocaelispor',
            'Galatasaray',
            'VS',
            DateTime.now().add(const Duration(days: 5)),
            false,
          ),
        ],
      ),
    );
  }

  Widget _buildMatchCard(String team1, String team2, String score, DateTime date, bool isResult) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                team1,
                style: const TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isResult ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                score,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isResult ? Colors.green.shade700 : Colors.orange.shade700,
                ),
              ),
            ),
            Expanded(
              child: Text(
                team2,
                style: const TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
            Icon(
              isResult ? Icons.check_circle : Icons.schedule,
              color: isResult ? Colors.green : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  // Hızlı erişim menüsü (admin için özel seçenekler ile)
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NewsPage()),
                  );
                },
                child: const Text('Tümünü Gör'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('haberler')
                .orderBy('tarih', descending: true)
                .limit(3)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(Icons.article_outlined, size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(
                          'Henüz haber yok',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        if (_isAdmin) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Admin olarak ilk haberi ekleyebilirsiniz',
                            style: TextStyle(
                              color: Colors.green.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.take(3).map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildNewsPreviewCard(data);
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNewsPreviewCard(Map<String, dynamic> newsData) {
    final tarih = newsData['tarih'] as Timestamp?;
    final formattedDate = tarih != null
        ? "${tarih.toDate().day}.${tarih.toDate().month}.${tarih.toDate().year}"
        : 'Tarih yok';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: newsData['resimUrl'] != null && newsData['resimUrl'].toString().isNotEmpty
            ? ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            newsData['resimUrl'],
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 60,
                height: 60,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image, color: Colors.grey),
              );
            },
          ),
        )
            : Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.article,
            color: AppTheme.primaryGreen,
          ),
        ),
        title: Text(
          newsData['baslik'] ?? 'Başlık Yok',
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          formattedDate,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NewsPage()),
          );
        },
      ),
    );
  }

  // Admin için özel hızlı eylemler paneli
  Widget _buildAdminQuickActions() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.admin_panel_settings, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                'Yönetici Hızlı Eylemler',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.5,
            children: [
              _buildAdminActionCard(
                'Haber Ekle',
                Icons.add_circle,
                Colors.blue,
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NewsPage()),
                ),
              ),
              _buildAdminActionCard(
                'Puan Güncelle',
                Icons.table_chart,
                Colors.green,
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PuanDurumuSayfasi()),
                ),
              ),
              _buildAdminActionCard(
                'Oyuncu Ekle',
                Icons.person_add,
                Colors.purple,
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KadroSayfasi()),
                ),
              ),
              _buildAdminActionCard(
                'Admin Panel',
                Icons.dashboard,
                Colors.orange,
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}