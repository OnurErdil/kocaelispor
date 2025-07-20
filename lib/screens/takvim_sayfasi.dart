// lib/screens/takvim_sayfasi.dart - ANASAYFA GİBİ GÜZEL RENK TASARIMI
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/analytics_service.dart';
import '../services/admin_service.dart';
import 'puan_durumu_sayfasi.dart';
import 'all_fixtures_page.dart';

class TakvimSayfasi extends StatefulWidget {
  const TakvimSayfasi({super.key});

  @override
  State<TakvimSayfasi> createState() => _TakvimSayfasiState();
}

class _TakvimSayfasiState extends State<TakvimSayfasi> with SingleTickerProviderStateMixin {
  bool _isAdmin = false;
  bool _isCheckingAdmin = true;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkAdminStatus();
    AnalyticsService.logViewFixture();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
    return Scaffold(
      // 🎨 KOYU ARKA PLAN - Anasayfa gibi
      backgroundColor: const Color(0xFF121212),

      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80), // Daha yüksek AppBar
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade800,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // 🎨 Sol taraf - Logo ve başlık (anasayfa gibi)
                  Row(
                    children: [
                      // Top logosu (ileride değişecek)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00913C),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.sports_soccer,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Başlık ve alt yazı
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TAKVİM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Kocaelispor Taraftar Uygulaması',
                            style: TextStyle(
                              color: Colors.green.shade400,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // FloatingActionButton sadece admin için göster - 🎨 Yeşil tema
      floatingActionButton: _isAdmin
          ? Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF00913C), // Kocaelispor yeşili
              Color(0xFF007A32), // Daha koyu yeşil
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00913C).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showAddMatchDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      )
          : null,

      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          // 🎨 Refresh indicator'ı yeşil yap
          color: const Color(0xFF00913C),
          backgroundColor: const Color(0xFF1E1E1E),
          onRefresh: () async {
            setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 🎨 Son maç bölümü
                _buildSectionTitle(Icons.history, 'Son Maç'),
                const SizedBox(height: 12),
                _buildLastMatch(),
                const SizedBox(height: 24),

                // 🎨 Sıradaki maç bölümü
                _buildSectionTitle(Icons.schedule, 'Sıradaki Maç'),
                const SizedBox(height: 12),
                _buildNextMatch(),
                const SizedBox(height: 24),

                // 🎨 Hızlı erişim butonları
                _buildQuickActions(),
                const SizedBox(height: 24),

                // 🎨 Yaklaşan maçlar
                _buildSectionTitle(Icons.calendar_month, 'Yaklaşan Maçlar'),
                const SizedBox(height: 12),
                _buildUpcomingMatches(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🎨 Bölüm başlığı - güzel tasarım
  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00913C).withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF00913C),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // 🎨 Son maç widget'ı
  Widget _buildLastMatch() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('maclar')
          .orderBy('tarih', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorCard('Son maç yüklenemedi');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyCard('Henüz oynanmış maç bulunmuyor');
        }

        // Biten maçları filtrele
        final finishedMatches = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final skor = data['skor'];
          if (skor == null) return false;

          if (skor is Map) {
            final evSahibiSkor = skor['ev_sahibi'] ?? skor['evSahibi'];
            final deplasmanSkor = skor['deplasman'] ?? skor['rakip'];
            return evSahibiSkor != null && deplasmanSkor != null;
          }
          return false;
        }).toList();

        if (finishedMatches.isEmpty) {
          return _buildEmptyCard('Henüz oynanmış maç bulunmuyor');
        }

        return _buildMatchCard(finishedMatches.first, isLastMatch: true);
      },
    );
  }

  // 🎨 Sıradaki maç widget'ı
  Widget _buildNextMatch() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('maclar')
          .where('tarih', isGreaterThan: Timestamp.now())
          .orderBy('tarih', descending: false)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorCard('Sıradaki maç yüklenemedi');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyCard('Yaklaşan maç bulunmuyor');
        }

        return _buildMatchCard(snapshot.data!.docs.first, isNextMatch: true);
      },
    );
  }

  // 🎨 Maç kartı - anasayfa gibi güzel tasarım
  Widget _buildMatchCard(DocumentSnapshot doc, {bool isLastMatch = false, bool isNextMatch = false}) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = data['tarih'] as Timestamp?;
    final homeTeam = data['ev_sahibi'] ?? 'Kocaelispor';
    final awayTeam = data['deplasman'] ?? 'Rakip';
    final stad = data['stad'] ?? 'Stadyum';

    // Skor bilgilerini al
    String homeScore = '0';
    String awayScore = '0';
    bool hasScore = false;

    if (data['skor'] != null) {
      final skor = data['skor'];
      if (skor is Map) {
        homeScore = (skor['ev_sahibi'] ?? skor['evSahibi'] ?? 0).toString();
        awayScore = (skor['deplasman'] ?? skor['rakip'] ?? 0).toString();
        hasScore = true;
      }
    }

    final isKocaelisporHome = homeTeam.toLowerCase().contains('kocaelispor');
    final matchResult = hasScore ? _calculateMatchResult(homeScore, awayScore, isKocaelisporHome) : '';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1E1E1E),
            const Color(0xFF2D2D2D),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLastMatch ? const Color(0xFF00913C).withOpacity(0.5) : Colors.orange.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🎨 Maç durumu etiketi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isLastMatch
                      ? [const Color(0xFF00913C), const Color(0xFF007A32)]
                      : [Colors.orange.shade600, Colors.orange.shade700],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isLastMatch ? 'SON MAÇ' : 'SIRADAKİ MAÇ',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 🎨 Takımlar ve skor
            Row(
              children: [
                // Ev sahibi takım
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        homeTeam,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isKocaelisporHome ? const Color(0xFF00913C) : Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      if (hasScore)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            homeScore,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // VS veya skor ayrımı
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    hasScore ? ':' : 'VS',
                    style: TextStyle(
                      fontSize: hasScore ? 24 : 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),

                // Deplasman takımı
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        awayTeam,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: !isKocaelisporHome ? const Color(0xFF00913C) : Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      if (hasScore)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            awayScore,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // 🎨 Maç bilgileri
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tarih
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatMatchDate(timestamp),
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  // Stadyum
                  Row(
                    children: [
                      Icon(
                        Icons.stadium,
                        size: 16,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        stad,
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 🎨 Maç sonucu (varsa)
            if (matchResult.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getResultColor(matchResult).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getResultColor(matchResult).withOpacity(0.5),
                  ),
                ),
                child: Text(
                  matchResult,
                  style: TextStyle(
                    color: _getResultColor(matchResult),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 🎨 Hızlı erişim butonları
  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.table_chart,
            title: 'Puan Durumu',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PuanDurumuSayfasi()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            icon: Icons.calendar_view_month,
            title: 'Tüm Fikstür',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AllFixturesPage()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00913C).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF00913C),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🎨 Yaklaşan maçlar
  Widget _buildUpcomingMatches() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('maclar')
          .where('tarih', isGreaterThan: Timestamp.now())
          .orderBy('tarih', descending: false)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorCard('Yaklaşan maçlar yüklenemedi');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyCard('Yaklaşan maç bulunmuyor');
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildCompactMatchCard(doc),
            );
          }).toList(),
        );
      },
    );
  }

  // 🎨 Kompakt maç kartı
  Widget _buildCompactMatchCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final homeTeam = data['ev_sahibi'] ?? 'Kocaelispor';
    final awayTeam = data['deplasman'] ?? 'Rakip';
    final timestamp = data['tarih'] as Timestamp?;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Row(
        children: [
          // Tarih
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00913C).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatCompactDate(timestamp),
              style: const TextStyle(
                color: Color(0xFF00913C),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Takımlar
          Expanded(
            child: Text(
              '$homeTeam vs $awayTeam',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Saat
          Text(
            _formatMatchTime(timestamp),
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 Yükleme kartı
  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00913C)),
        ),
      ),
    );
  }

  // 🎨 Hata kartı
  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 Boş kart
  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        children: [
          Icon(
            Icons.sports_soccer,
            size: 48,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 12),
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
    );
  }

  // Yardımcı fonksiyonlar
  String _formatMatchDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Tarih yok';

    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Bugün ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference == 1) {
      return 'Yarın ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference == -1) {
      return 'Dün';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  String _formatCompactDate(Timestamp? timestamp) {
    if (timestamp == null) return '??/??';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}';
  }

  String _formatMatchTime(Timestamp? timestamp) {
    if (timestamp == null) return '??:??';
    final date = timestamp.toDate();
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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

  Color _getResultColor(String result) {
    switch (result) {
      case 'GALİBİYET':
        return const Color(0xFF00913C);
      case 'BERABERLİK':
        return Colors.orange;
      case 'MAĞLUBİYET':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Admin işlemleri
  void _showAddMatchDialog() {
    // Maç ekleme dialogu (admin için)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Yeni Maç Ekle',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Maç ekleme özelliği yakında eklenecek!',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Tamam',
              style: TextStyle(color: Color(0xFF00913C)),
            ),
          ),
        ],
      ),
    );
  }
}