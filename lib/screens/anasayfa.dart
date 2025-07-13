// lib/screens/anasayfa.dart - DOĞRU İMPORT SIRASI
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';                    // ✅ YENİ EKLENDİ
import '../providers/tab_provider.dart';                   // ✅ YENİ EKLENDİ
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
          actions: _isAdmin && !_isCheckingAdmin
              ? [
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminPanelScreen(),
                  ),
                );
              },
              tooltip: 'Admin Panel',
            ),
          ]
              : null,
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Hoş geldin mesajı
                _buildWelcomeSection(),

                // Hızlı erişim butonları
                _buildQuickAccessSection(),

                // Son maçlar
                _buildMatchSection(),

                // Son haberler
                _buildNewsSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Hoş geldin bölümü
  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, Colors.green],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kocaelispor 1966',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isAdmin && !_isCheckingAdmin
                      ? '🔧 Yönetici Paneline Erişim Var'
                      : '⚽ Kocaelispor\'a Hoş Geldin!',
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

  // ✅ HIZLI ERİŞİM BÖLÜMÜ - Tab değiştirme ile
  Widget _buildQuickAccessSection() {
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
          Row(
            children: [
              Expanded(
                child: _buildQuickAccessCard(
                  'Kadro',
                  Icons.people,
                      () {
                    // ✅ Provider kullanarak tab değiştir
                    context.read<TabProvider>().changeTab(1);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAccessCard(
                  'Takvim',
                  Icons.calendar_today,
                      () {
                    context.read<TabProvider>().changeTab(2);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAccessCard(
                  'Forum',
                  Icons.forum,
                      () {
                    context.read<TabProvider>().changeTab(3);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildQuickAccessCard(
                  'Galeri',
                  Icons.photo_library,
                      () {
                    context.read<TabProvider>().changeTab(4);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickAccessCard(
                  'Profil',
                  Icons.person,
                      () {
                    context.read<TabProvider>().changeTab(5);
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Boş alan
              Expanded(child: Container()),
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
              color: isResult ? Colors.green.shade600 : Colors.orange.shade600,
            ),
          ],
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
              // Yükleniyor durumu
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                  ),
                );
              }

              // Hata durumu
              if (snapshot.hasError) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 8),
                        Text(
                          'Haberler yüklenirken hata oluştu',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () => setState(() {}),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Veri yoksa
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
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AdminPanelScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Haber Ekle'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              // Haberler listesi
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

  // Haber önizleme kartı
  Widget _buildNewsPreviewCard(Map<String, dynamic> data) {
    final title = data['baslik'] ?? 'Başlık Yok';
    final content = data['icerik'] ?? '';
    final category = data['kategori'] ?? 'Genel';
    final date = data['tarih']?.toDate() ?? DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          _showSimpleNewsDetail(title, content, category, date);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kategori badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getCategoryColor(category).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getCategoryColor(category),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Başlık
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // İçerik önizleme
              Text(
                content,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Tarih ve okuma işareti
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatSimpleDate(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Basit haber detayı
  void _showSimpleNewsDetail(String title, String content, String category, DateTime date) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Kategori
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(category).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getCategoryColor(category),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // İçerik
              Text(content),
              const SizedBox(height: 12),
              // Tarih
              Text(
                _formatSimpleDate(date),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
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

  // Kategori rengi
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'transfer':
        return Colors.blue.shade600;
      case 'maç':
      case 'mac':
        return Colors.green.shade600;
      case 'takım':
      case 'takim':
        return Colors.orange.shade600;
      case 'kulüp':
      case 'kulup':
        return Colors.purple.shade600;
      default:
        return AppTheme.primaryGreen;
    }
  }

  // Basit tarih formatı
  String _formatSimpleDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} dk önce';
      }
      return '${difference.inHours} saat önce';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}