// lib/screens/takvim_sayfasi.dart - YENİ YAPIYLA TAM VERSİYON
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';
import '../services/admin_service.dart';
import '../services/analytics_service.dart';
import 'puan_durumu_sayfasi.dart';

class TakvimSayfasi extends StatefulWidget {
  const TakvimSayfasi({super.key});

  @override
  State<TakvimSayfasi> createState() => _TakvimSayfasiState();
}

class _TakvimSayfasiState extends State<TakvimSayfasi> with TickerProviderStateMixin {
  bool _isAdmin = false;
  bool _isCheckingAdmin = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Yeni değişkenler
  bool _showAllFixtures = false; // Tüm fikstürü göster/gizle

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
    AnalyticsService.logViewFixture();
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
      backgroundColor: const Color(0xFF0F0F0F), // Forum ile aynı koyu arka plan
      appBar: const CustomAppBar(
        title: "Sonuçlar & Fikstür", // YENİ BAŞLIK
      ),
      floatingActionButton: _isAdmin ? _buildFAB() : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0F0F), // Koyu siyah
              Color(0xFF1A1A1A), // Koyu gri
              Color(0xFF0F0F0F), // Tekrar koyu siyah
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            // Admin kontrol çubuğu
            if (_isCheckingAdmin) _buildLoadingBar(),
            if (!_isCheckingAdmin && _isAdmin) _buildAdminBar(),

            // Ana içerik
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Son Maç
                      _buildSectionTitle('SON MAÇ:', Icons.sports_soccer),
                      const SizedBox(height: 16),
                      _buildLastMatch(),

                      const SizedBox(height: 24),

                      // Sıradaki Maç
                      _buildSectionTitle('SIRADAKİ MAÇ:', Icons.schedule),
                      const SizedBox(height: 16),
                      _buildNextMatch(),

                      const SizedBox(height: 24),

                      // Fikstür Butonu
                      _buildFixtureButton(),

                      const SizedBox(height: 16),

                      // Tüm Fikstür (butona basınca görünür)
                      if (_showAllFixtures) _buildAllFixtures(),

                      const SizedBox(height: 32),

                      // Hızlı erişim butonları
                      _buildQuickActions(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Loading bar
  Widget _buildLoadingBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.grey.shade800,
      child: const Center(
        child: Text(
          'Yetki kontrolü yapılıyor...',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  // Admin bar
  Widget _buildAdminBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: AppTheme.primaryGreen.withOpacity(0.2),
      child: Row(
        children: [
          Icon(Icons.admin_panel_settings, color: AppTheme.primaryGreen),
          const SizedBox(width: 8),
          const Text(
            'Admin modunda - Maç ekleyebilir ve düzenleyebilirsiniz',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  // Section title
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryGreen,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // Son maç gösterimi
  Widget _buildLastMatch() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('maclar')
          .where('tarih', isLessThan: Timestamp.now())
          .where('skor', isNotEqualTo: null)  // Skoru girilmiş maçlar
          .orderBy('tarih', descending: true)
          .limit(1)
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

        final doc = snapshot.data!.docs.first;
        return _buildMatchCard(doc, isLastMatch: true);
      },
    );
  }

  // Sıradaki maç gösterimi
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

        final doc = snapshot.data!.docs.first;
        return _buildMatchCard(doc, isNextMatch: true);
      },
    );
  }

  // Fikstür butonu
  Widget _buildFixtureButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            _showAllFixtures = !_showAllFixtures;
          });
        },
        icon: Icon(
          _showAllFixtures ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
          color: Colors.white,
        ),
        label: Text(
          _showAllFixtures ? 'FİKSTÜRÜ GİZLE' : 'FİKSTÜRÜ GÖSTER',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // Tüm fikstür gösterimi
  Widget _buildAllFixtures() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('TÜM FİKSTÜR:', Icons.list),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('maclar')
              .orderBy('tarih', descending: false)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorCard('Fikstür yüklenemedi');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingCard();
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyCard('Henüz maç bulunmuyor');
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildMatchCard(doc, showAllDetails: true),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  // Geliştirilmiş maç kartı
  Widget _buildMatchCard(DocumentSnapshot doc, {
    bool isLastMatch = false,
    bool isNextMatch = false,
    bool showAllDetails = false,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = data['tarih'] as Timestamp?;
    final homeTeam = data['ev_sahibi'] as String? ?? 'Kocaelispor';
    final awayTeam = data['deplasman'] as String? ?? 'Rakip';
    final homeScore = data['skor']?['ev_sahibi'];
    final awayScore = data['skor']?['deplasman'];
    final homeLogoUrl = data['ev_sahibi_logo'] as String?;
    final awayLogoUrl = data['deplasman_logo'] as String?;

    final matchDate = timestamp?.toDate() ?? DateTime.now();
    final isFinished = homeScore != null && awayScore != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLastMatch
              ? Colors.green.withOpacity(0.5)
              : isNextMatch
              ? Colors.orange.withOpacity(0.5)
              : AppTheme.primaryGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Takım bilgileri
          Row(
            children: [
              // Ev sahibi takım
              Expanded(
                child: Column(
                  children: [
                    _buildTeamLogo(homeLogoUrl, 40),
                    const SizedBox(height: 8),
                    Text(
                      homeTeam,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Skor veya tarih
              Expanded(
                child: Column(
                  children: [
                    if (isFinished) ...[
                      // Skor gösterimi
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$homeScore - $awayScore',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ] else ...[
                      // Tarih gösterimi
                      Column(
                        children: [
                          Text(
                            '${matchDate.day} ${_getMonthName(matchDate.month)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${matchDate.hour.toString().padLeft(2, '0')}:${matchDate.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Deplasman takım
              Expanded(
                child: Column(
                  children: [
                    _buildTeamLogo(awayLogoUrl, 40),
                    const SizedBox(height: 8),
                    Text(
                      awayTeam,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Admin butonları
          if (_isAdmin && !isFinished) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showScoreDialog(doc.id, homeTeam, awayTeam),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Skor Gir'),
            ),
          ],

          // Admin düzenleme butonu (tüm maçlar için)
          if (_isAdmin && showAllDetails) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!isFinished)
                  ElevatedButton(
                    onPressed: () => _showScoreDialog(doc.id, homeTeam, awayTeam),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Skor Gir'),
                  ),
                ElevatedButton(
                  onPressed: () => _showMatchOptions(doc.id, data),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Düzenle'),
                ),
              ],
            ),
          ],

          // Geri sayım (sadece sıradaki maç için)
          if (isNextMatch && !isFinished) ...[
            const SizedBox(height: 12),
            _CountdownWidget(matchDate: matchDate, isKocaelisporTheme: true),
          ],
        ],
      ),
    );
  }

  // Error card
  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 8),
          Text(message, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  // Loading card
  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
        ),
      ),
    );
  }

  // Empty card
  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // Team logo
  Widget _buildTeamLogo(String? logoUrl, double size) {
    if (logoUrl == null || logoUrl.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.sports_soccer,
          size: size * 0.6,
          color: AppTheme.primaryGreen,
        ),
      );
    }

    return ClipOval(
      child: Image.network(
        logoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sports_soccer,
              size: size * 0.6,
              color: AppTheme.primaryGreen,
            ),
          );
        },
      ),
    );
  }

  // Month name
  String _getMonthName(int month) {
    const months = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return months[month];
  }

  // Quick actions
  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D), // Forum kart rengi
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PuanDurumuSayfasi(),
                  ),
                );
              },
              icon: const Icon(Icons.leaderboard, color: Colors.white),
              label: const Text(
                'Puan Durumu',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FAB
  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: _showAddMatchDialog,
      backgroundColor: AppTheme.primaryGreen,
      child: const Icon(Icons.add, color: Colors.white),
    );
  }

  // Skor girme dialog'u
  void _showScoreDialog(String docId, String homeTeam, String awayTeam) {
    final homeController = TextEditingController();
    final awayController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Maç Sonucu',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        homeTeam,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: homeController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  '-',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        awayTeam,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: awayController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              final homeScore = int.tryParse(homeController.text);
              final awayScore = int.tryParse(awayController.text);

              if (homeScore == null || awayScore == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Geçerli skor giriniz!'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('maclar')
                    .doc(docId)
                    .update({
                  'skor': {
                    'ev_sahibi': homeScore,
                    'deplasman': awayScore,
                  },
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Skor başarıyla kaydedildi!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Hata: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  // Match options
  void _showMatchOptions(String docId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Maç İşlemleri',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.green),
              title: const Text('Düzenle', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showEditMatchDialog(docId, data);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Sil', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _deleteMatch(docId);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Add match dialog
  void _showAddMatchDialog() {
    final homeTeamController = TextEditingController();
    final awayTeamController = TextEditingController();
    final dateController = TextEditingController();
    final timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Yeni Maç Ekle',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: homeTeamController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Ev Sahibi Takım',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: awayTeamController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Deplasman Takım',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dateController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Tarih (YYYY-MM-DD)',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timeController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Saat (HH:MM)',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final dateTime = DateTime.parse('${dateController.text} ${timeController.text}:00');

                await FirebaseFirestore.instance.collection('maclar').add({
                  'ev_sahibi': homeTeamController.text,
                  'deplasman': awayTeamController.text,
                  'tarih': Timestamp.fromDate(dateTime),
                  'createdAt': Timestamp.now(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Maç başarıyla eklendi!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Hata: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  // Edit match dialog
  void _showEditMatchDialog(String docId, Map<String, dynamic> data) {
    final homeTeamController = TextEditingController(text: data['ev_sahibi'] ?? '');
    final awayTeamController = TextEditingController(text: data['deplasman'] ?? '');

    final timestamp = data['tarih'] as Timestamp?;
    final date = timestamp?.toDate() ?? DateTime.now();
    final dateController = TextEditingController(
        text: '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
    );
    final timeController = TextEditingController(
        text: '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Maç Düzenle',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: homeTeamController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Ev Sahibi Takım',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: awayTeamController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Deplasman Takım',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dateController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Tarih (YYYY-MM-DD)',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timeController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Saat (HH:MM)',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final dateTime = DateTime.parse('${dateController.text} ${timeController.text}:00');

                await FirebaseFirestore.instance
                    .collection('maclar')
                    .doc(docId)
                    .update({
                  'ev_sahibi': homeTeamController.text,
                  'deplasman': awayTeamController.text,
                  'tarih': Timestamp.fromDate(dateTime),
                  'updatedAt': Timestamp.now(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Maç başarıyla güncellendi!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Hata: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }

  // Delete match
  void _deleteMatch(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Maç Sil',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Bu maçı silmek istediğinizden emin misiniz?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('maclar')
                    .doc(docId)
                    .delete();

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Maç başarıyla silindi!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Hata: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

// ✅ Ayrı Geri Sayım Widget'ı - Forum Teması
class _CountdownWidget extends StatefulWidget {
  final DateTime matchDate;
  final bool isKocaelisporTheme;

  const _CountdownWidget({
    required this.matchDate,
    this.isKocaelisporTheme = false,
  });

  @override
  State<_CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<_CountdownWidget> {
  late Timer _timer;
  String _countdown = '';

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateCountdown();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final difference = widget.matchDate.difference(now);

    if (difference.isNegative) {
      setState(() {
        _countdown = '00:00:00:00';
      });
      return;
    }

    final days = difference.inDays;
    final hours = difference.inHours % 24;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;

    setState(() {
      _countdown = '${days.toString().padLeft(2, '0')}:${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isKocaelisporTheme
            ? const Color(0xFF2D2D2D) // Forum kart rengi
            : AppTheme.primaryGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: widget.isKocaelisporTheme ? Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.3),
          width: 1,
        ) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'KICK OFF IN:',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: widget.isKocaelisporTheme ? Colors.grey.shade400 : AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _countdown,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.isKocaelisporTheme ? Colors.white : AppTheme.primaryGreen,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            'GÜN:SAAT:DAK:SAN',
            style: TextStyle(
              fontSize: 8,
              color: widget.isKocaelisporTheme ? Colors.grey.shade500 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}