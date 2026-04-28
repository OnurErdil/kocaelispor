// lib/screens/anasayfa.dart - YENİ TASARIM
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/tab_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/analytics_wrapper.dart';
import '../services/analytics_service.dart';
import '../services/admin_service.dart';
import '../theme/app_theme.dart';
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
  PageController _photoController = PageController();
  int _currentPhotoIndex = 0;

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
    _photoController.dispose();
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
        backgroundColor: Colors.black,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Özel header
                _buildCustomHeader(),

                // Menü çubuğu
                _buildMenuBar(),

                // Takım fotoları slider'ı
                _buildTeamPhotosSlider(),

                // Haber sayfası erişimi
                _buildNewsAccess(),

                // Maç sonuçları
                _buildMatchResults(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Özel header yapısı
  Widget _buildCustomHeader() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Colors.grey.shade900,
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Kocaelispor logosu
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.sports_soccer,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),

              // Başlık yazıları
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'KOCAELİSPOR',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Taraftar Uygulaması',
                      style: TextStyle(
                        color: Colors.green.shade400,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Admin butonu (eğer admin ise)
              if (_isAdmin && !_isCheckingAdmin)
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
                    );
                  },
                  icon: Icon(
                    Icons.admin_panel_settings,
                    color: Colors.yellow.shade600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Menü çubuğu
  Widget _buildMenuBar() {
    // Bu indexler, lib/screens/main_screen.dart içindeki _pages sırası ile aynı olmalı.
    // MainScreen sırası:
    // 0 Ana Sayfa, 1 Haberler, 2 Kadro, 3 Fikstür, 4 Forum, 5 Galeri, 6 Profil
    final menuItems = [
      {'title': 'Ana Sayfa', 'icon': Icons.home_outlined, 'index': 0},
      {'title': 'Haberler', 'icon': Icons.newspaper, 'index': 1},
      {'title': 'Kadro', 'icon': Icons.people_outline, 'index': 2},
      {'title': 'Fikstür', 'icon': Icons.calendar_month, 'index': 3},
      {'title': 'Puan Durumu', 'icon': Icons.emoji_events, 'index': 3},
      {'title': 'Forum', 'icon': Icons.chat_bubble_outline, 'index': 4},
      {'title': 'Galeri', 'icon': Icons.image, 'index': 5},
      {'title': 'Profil', 'icon': Icons.account_circle, 'index': 6},
    ];

    return Container(
      height: 76,
      color: Colors.grey.shade900,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return _buildMenuItem(
            title: item['title'] as String,
            icon: item['icon'] as IconData,
            onTap: () => _handleMenuTap(item['index'] as int),
          );
        },
      ),
    );
  }

  // Menü öğesi
  Widget _buildMenuItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 86,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade700, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.green.shade400,
              size: 19,
            ),
            const SizedBox(height: 3),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Menü tıklama işlevi
  void _handleMenuTap(int index) {
    // Geçersiz index gelirse uygulama hata vermesin diye güvenlik kontrolü.
    if (index < 0 || index > 6) {
      return;
    }
    final tabProvider = Provider.of<TabProvider>(context, listen: false);
    tabProvider.changeTab(index);
  }

  // Takım fotoları slider'ı
  Widget _buildTeamPhotosSlider() {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('team_photos')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildPhotoSliderLoading();
          }

          if (snapshot.hasError) {
            return _buildPhotoSliderError();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildPhotoSliderEmpty();
          }

          final photos = snapshot.data!.docs;

          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _photoController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPhotoIndex = index;
                    });
                  },
                  itemCount: photos.length,
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    final imageUrl = photo['image_url'] as String? ?? '';
                    final title = photo['title'] as String? ?? 'Takım Fotoğrafı';

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade700, width: 2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          children: [
                            // Fotoğraf
                            imageUrl.isNotEmpty
                                ? Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPhotoError();
                              },
                            )
                                : _buildPhotoError(),

                            // Başlık overlay
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Sayfa göstergeleri
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  photos.length,
                      (index) => Container(
                    width: _currentPhotoIndex == index ? 20 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _currentPhotoIndex == index
                          ? Colors.green.shade400
                          : Colors.grey.shade600,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Fotoğraf yükleme durumu
  Widget _buildPhotoSliderLoading() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade700, width: 2),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
        ),
      ),
    );
  }

  // Fotoğraf hata durumu
  Widget _buildPhotoSliderError() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade700, width: 2),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red, size: 40),
            SizedBox(height: 8),
            Text(
              'Fotoğraflar yüklenemedi',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // Boş fotoğraf durumu
  Widget _buildPhotoSliderEmpty() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade700, width: 2),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library, color: Colors.grey, size: 40),
            SizedBox(height: 8),
            Text(
              'Henüz takım fotoğrafı eklenmemiş',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Fotoğraf hata widget'ı
  Widget _buildPhotoError() {
    return Container(
      color: Colors.grey.shade800,
      child: const Center(
        child: Icon(
          Icons.broken_image,
          color: Colors.grey,
          size: 40,
        ),
      ),
    );
  }

  // Haber sayfası erişimi
  Widget _buildNewsAccess() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        color: Colors.grey.shade900,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.green.shade700, width: 1),
        ),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NewsPage()),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.green.shade700,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.article,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Son Haberler',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Takımımız hakkında son haberleri okuyun',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.green.shade400,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Maç sonuçları bölümü
  Widget _buildMatchResults() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Maçlar',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Biten maç - DÜZELTİLDİ
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('maclar')
                .orderBy('tarih', descending: true)
                .limit(20)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingMatchCard('Son Maç');
              }

              if (snapshot.hasError) {
                return _buildErrorMatchCard('Son Maç', 'Yüklenemedi');
              }

              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                // Biten maçları filtrele (skor varsa biten maç)
                final finishedMatches = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final skor = data['skor'];

                  if (skor == null) return false;

                  if (skor is Map) {
                    final evSkor = skor['ev_sahibi'];
                    final deplasmanSkor = skor['deplasman'];
                    return evSkor != null && deplasmanSkor != null;
                  }

                  return false;
                }).toList();

                if (finishedMatches.isNotEmpty) {
                  final match = finishedMatches.first;
                  final data = match.data() as Map<String, dynamic>;
                  return _buildMatchCard(
                    homeTeam: data['ev_sahibi'] ?? 'Ev Sahibi',
                    awayTeam: data['deplasman'] ?? 'Deplasman',
                    homeScore: _getScoreFromSkor(data['skor'], 'ev_sahibi'),
                    awayScore: _getScoreFromSkor(data['skor'], 'deplasman'),
                    date: _formatMatchDate(data['tarih']),
                    isFinished: true,
                    isHome: _isKocaelisporHome(data['ev_sahibi']),
                    stadium: data['stad'] ?? '',
                  );
                }
              }
              return _buildEmptyMatchCard('Son Maç', 'Henüz biten maç yok');
            },
          ),

          const SizedBox(height: 8),

          // Sıradaki maç - DÜZELTİLDİ
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('maclar')
                .where('tarih', isGreaterThan: Timestamp.now())
                .orderBy('tarih', descending: false)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingMatchCard('Sıradaki Maç');
              }

              if (snapshot.hasError) {
                return _buildErrorMatchCard('Sıradaki Maç', 'Yüklenemedi');
              }

              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                // Yaklaşan maçları filtrele (skor yoksa yaklaşan maç)
                final upcomingMatches = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final skor = data['skor'];
                  return skor == null;
                }).toList();

                if (upcomingMatches.isNotEmpty) {
                  final match = upcomingMatches.first;
                  final data = match.data() as Map<String, dynamic>;
                  return _buildMatchCard(
                    homeTeam: data['ev_sahibi'] ?? 'Ev Sahibi',
                    awayTeam: data['deplasman'] ?? 'Deplasman',
                    homeScore: '',
                    awayScore: '',
                    date: _formatMatchDate(data['tarih']),
                    isFinished: false,
                    isHome: _isKocaelisporHome(data['ev_sahibi']),
                    stadium: data['stad'] ?? '',
                  );
                }
              }
              return _buildEmptyMatchCard('Sıradaki Maç', 'Henüz planlanmış maç yok');
            },
          ),
        ],
      ),
    );
  }

  // Geliştirilmiş maç kartı
  Widget _buildMatchCard({
    required String homeTeam,
    required String awayTeam,
    required String homeScore,
    required String awayScore,
    required String date,
    required bool isFinished,
    required bool isHome,
    required String stadium,
  }) {
    return Card(
      color: Colors.grey.shade900,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade700, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Başlık
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isFinished ? Colors.green.shade700 : Colors.orange.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isFinished ? 'Son Maç' : 'Sıradaki Maç',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Takımlar ve skor
            Row(
              children: [
                // Ev sahibi takım
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        homeTeam,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isHome)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'EV',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Skor bölümü
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isFinished ? Colors.green.shade700 : Colors.orange.shade700,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        isFinished ? '$homeScore - $awayScore' : 'VS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isFinished)
                        Text(
                          _calculateMatchResult(homeScore, awayScore, isHome),  // ← YENİ FONKSİYON
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),

                // Deplasman takım
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        awayTeam,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!isHome)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'EV',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Tarih ve stad bilgisi
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Tarih
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFinished ? Icons.check_circle : Icons.schedule,
                      color: Colors.grey.shade400,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                // Stad
                if (stadium.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.stadium,
                        color: Colors.grey.shade400,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        stadium,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
              ],
            ),

            // Maç detayları butonu
            if (isFinished)
              Container(
                margin: const EdgeInsets.only(top: 12),
                child: TextButton(
                  onPressed: () {
                    // Maç detayları sayfasına git
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Maç detayları yakında eklenecek'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  child: Text(
                    'Maç Detayları',
                    style: TextStyle(
                      color: Colors.green.shade400,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Yükleniyor kartı
  Widget _buildLoadingMatchCard(String title) {
    return Card(
      color: Colors.grey.shade900,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade700, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.green.shade400,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Yükleniyor...',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Hata kartı
  Widget _buildErrorMatchCard(String title, String message) {
    return Card(
      color: Colors.grey.shade900,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade700, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.red.shade400,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.red.shade400,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Boş maç kartı (eski hali - değişmez)
  Widget _buildEmptyMatchCard(String title, String message) {
    return Card(
      color: Colors.grey.shade900,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade700, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: Colors.green.shade400,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Yardımcı fonksiyonlar
  String _formatMatchDate(dynamic date) {
    if (date == null) return 'Tarih yok';

    try {
      DateTime matchDate;
      if (date is Timestamp) {
        matchDate = date.toDate();
      } else if (date is DateTime) {
        matchDate = date;
      } else {
        return 'Geçersiz tarih';
      }

      final now = DateTime.now();
      final difference = matchDate.difference(now).inDays;

      if (difference == 0) {
        return 'Bugün ${matchDate.hour.toString().padLeft(2, '0')}:${matchDate.minute.toString().padLeft(2, '0')}';
      } else if (difference == 1) {
        return 'Yarın ${matchDate.hour.toString().padLeft(2, '0')}:${matchDate.minute.toString().padLeft(2, '0')}';
      } else if (difference == -1) {
        return 'Dün ${matchDate.hour.toString().padLeft(2, '0')}:${matchDate.minute.toString().padLeft(2, '0')}';
      } else if (difference > 1 && difference <= 7) {
        return '${difference} gün sonra';
      } else if (difference < -1 && difference >= -7) {
        return '${difference.abs()} gün önce';
      } else {
        return '${matchDate.day.toString().padLeft(2, '0')}.${matchDate.month.toString().padLeft(2, '0')}.${matchDate.year}';
      }
    } catch (e) {
      return 'Tarih hatası';
    }
  }
  String _getScoreFromSkor(dynamic skor, String team) {
    if (skor == null) return '0';
    if (skor is Map) {
      return (skor[team] ?? '0').toString();
    }
    return '0';
  }

  bool _isKocaelisporHome(String? homeTeam) {
    if (homeTeam == null) return false;
    return homeTeam.toLowerCase().contains('kocaelispor');
  }
  String _calculateMatchResult(String homeScore, String awayScore, bool isHome) {
    try {
      final home = int.parse(homeScore);
      final away = int.parse(awayScore);

      if (home == away) {
        return 'BERABERLİK';
      } else if (isHome && home > away) {
        return 'GALİBİYET';
      } else if (!isHome && away > home) {
        return 'GALİBİYET';
      } else {
        return 'MAĞLUBİYET';
      }
    } catch (e) {
      return '';
    }
  }
  }