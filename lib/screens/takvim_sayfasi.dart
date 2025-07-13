// lib/screens/takvim_sayfasi.dart - Forum Uyumlu Koyu Tema - TAM VERSİYON
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
        title: "Fikstür & Takvim",
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
                      // Yaklaşan Maçlar
                      _buildSectionTitle('YAKLASAN MACLAR:', Icons.upcoming),
                      const SizedBox(height: 16),
                      _buildUpcomingMatches(),

                      const SizedBox(height: 32),

                      // Son Sonuçlar - Ay bazında gruplandırılmış
                      _buildSectionTitle('SON SONUCLAR:', Icons.history),
                      const SizedBox(height: 16),
                      _buildRecentResults(),

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

  Widget _buildLoadingBar() {
    return Container(
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
    );
  }

  Widget _buildAdminBar() {
    return Container(
      color: Colors.green.shade50,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.admin_panel_settings,
              color: Colors.green.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Yönetici modundasınız - Maçları yönetebilirsiniz',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white, // Beyaz başlık
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingMatches() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('maclar')
          .where('tarih', isGreaterThan: Timestamp.now())
          .orderBy('tarih')
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
            final data = doc.data() as Map<String, dynamic>;
            return _buildUpcomingMatchCard(data, doc.id);
          }).toList(),
        );
      },
    );
  }

  Widget _buildUpcomingMatchCard(Map<String, dynamic> data, String docId) {
    final timestamp = data['tarih'] as Timestamp?;
    if (timestamp == null) return const SizedBox.shrink();

    final matchDate = timestamp.toDate();
    final homeTeam = data['evSahibi'] ?? 'Kocaelispor';
    final awayTeam = data['deplasman'] ?? 'Rakip';
    final competition = data['lig'] ?? 'Lig';
    final venue = data['stadyum'] ?? 'Stadyum';
    final matchTime = data['saat'] ?? '21:00';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Sol tarih kutusu - Forum teması ile uyumlu
          Container(
            width: 80,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D), // Forum kartları ile aynı koyu gri
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${matchDate.day}',
                  style: const TextStyle(
                    color: Colors.white, // Beyaz tarih
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getMonthName(matchDate.month).toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey.shade400, // Açık gri ay
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  Icons.sports_soccer,
                  color: AppTheme.primaryGreen, // Yeşil ikon
                  size: 20,
                ),
              ],
            ),
          ),

          // Sağ içerik alanı
          Expanded(
            child: Container(
              height: 120,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A), // Forum surface rengi
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border.all(
                  color: Colors.grey.shade800,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  // Maç bilgileri
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Lig bilgisi
                        Text(
                          competition,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400, // Açık gri detaylar
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        // Saat ve stadyum
                        Text(
                          '$matchTime - $venue',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),

                        // Takımlar
                        Row(
                          children: [
                            // Ev sahibi
                            Expanded(
                              child: Row(
                                children: [
                                  _buildTeamLogo(data['evSahibiLogo'], 24),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      homeTeam,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white, // Beyaz takım isimleri
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // VS
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                'VS',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),

                            // Deplasman
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Text(
                                      awayTeam,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white, // Beyaz takım isimleri
                                      ),
                                      textAlign: TextAlign.right,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildTeamLogo(data['deplasmanLogo'], 24),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Geri sayım - Optimized StatefulWidget ile
                  _CountdownWidget(matchDate: matchDate, isKocaelisporTheme: true),

                  // Admin düzenleme
                  if (_isAdmin)
                    IconButton(
                      onPressed: () => _showMatchOptions(docId, data),
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentResults() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('maclar')
          .where('tarih', isLessThan: Timestamp.now())
          .where('skor', isNotEqualTo: null)
          .orderBy('tarih', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorCard('Son sonuçlar yüklenemedi');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyCard('Henüz oynanmış maç bulunmuyor');
        }

        // Maçları aya göre grupla
        final groupedMatches = _groupMatchesByMonth(snapshot.data!.docs);

        return Column(
          children: groupedMatches.entries.map((entry) {
            return _buildMonthSection(entry.key, entry.value);
          }).toList(),
        );
      },
    );
  }

  Map<String, List<QueryDocumentSnapshot>> _groupMatchesByMonth(List<QueryDocumentSnapshot> docs) {
    final Map<String, List<QueryDocumentSnapshot>> grouped = {};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['tarih'] as Timestamp?;
      if (timestamp == null) continue;

      final date = timestamp.toDate();
      final monthKey = '${_getMonthName(date.month).toUpperCase()} ${date.year}';

      if (!grouped.containsKey(monthKey)) {
        grouped[monthKey] = [];
      }
      grouped[monthKey]!.add(doc);
    }

    return grouped;
  }

  Widget _buildMonthSection(String monthYear, List<QueryDocumentSnapshot> matches) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ay başlığı - Forum teması
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          margin: const EdgeInsets.only(bottom: 16, top: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D), // Forum kart rengi
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.primaryGreen.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_month,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                monthYear,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Beyaz ay başlığı
                ),
              ),
            ],
          ),
        ),

        // Maç sonuçları
        ...matches.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _buildResultCard(data, doc.id);
        }).toList(),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildResultCard(Map<String, dynamic> data, String docId) {
    final timestamp = data['tarih'] as Timestamp?;
    if (timestamp == null) return const SizedBox.shrink();

    final matchDate = timestamp.toDate();
    final homeTeam = data['evSahibi'] ?? 'Kocaelispor';
    final awayTeam = data['deplasman'] ?? 'Rakip';
    final score = data['skor'] ?? '0-0';
    final competition = data['lig'] ?? 'Lig';
    final matchTime = data['saat'] ?? '21:00';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Sol tarih kutusu - Forum teması
          Container(
            width: 60,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF2D2D2D), // Forum kart rengi
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.sports_soccer,
                  color: AppTheme.primaryGreen, // Yeşil ikon
                  size: 16,
                ),
                const SizedBox(height: 4),
                Text(
                  '${matchDate.day}',
                  style: const TextStyle(
                    color: Colors.white, // Beyaz tarih
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _getMonthName(matchDate.month).substring(0, 3).toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey.shade400, // Açık gri ay
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Sağ içerik alanı
          Expanded(
            child: Container(
              height: 80,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A), // Forum surface rengi
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border.all(
                  color: Colors.grey.shade800,
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  // Maç bilgileri
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Lig ve saat
                        Row(
                          children: [
                            Text(
                              competition,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade400, // Açık gri detaylar
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              matchTime,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),

                        // Takımlar ve skor
                        Row(
                          children: [
                            // Ev sahibi
                            _buildTeamLogo(data['evSahibiLogo'], 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                homeTeam,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white, // Beyaz takım isimleri
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                            // Skor
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                score,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            // Deplasman
                            Expanded(
                              child: Text(
                                awayTeam,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white, // Beyaz takım isimleri
                                ),
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildTeamLogo(data['deplasmanLogo'], 20),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Admin düzenleme
                  if (_isAdmin)
                    IconButton(
                      onPressed: () => _showMatchOptions(docId, data),
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey.shade600,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  String _getMonthName(int month) {
    const months = [
      '', 'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return months[month];
  }

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
                  MaterialPageRoute(builder: (_) => const PuanDurumuSayfasi()),
                );
              },
              icon: const Icon(Icons.table_chart),
              label: const Text('Puan Durumu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D), // Forum kart rengi
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade800,
          width: 0.5,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D), // Forum kart rengi
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade800),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red.shade400),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.red.shade400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      height: 120,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D), // Forum kart rengi
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade800,
          width: 0.5,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, color: Colors.grey.shade500),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showMatchOptions(String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFF2D2D2D), // Forum kart rengi
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Maç İşlemleri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            ListTile(
              leading: Icon(Icons.edit, color: Colors.blue.shade400),
              title: const Text('Maçı Düzenle', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Düzenleme dialogu
              },
            ),

            ListTile(
              leading: Icon(Icons.delete, color: Colors.red.shade400),
              title: const Text('Maçı Sil', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteMatch(docId, data);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMatch(String docId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Maçı Sil', style: TextStyle(color: Colors.white)),
        content: const Text('Bu maçı silmek istediğinizden emin misiniz?',
            style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance.collection('maclar').doc(docId).delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Maç başarıyla silindi'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Maç silinemedi: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      backgroundColor: AppTheme.primaryGreen,
      child: const Icon(Icons.add, color: Colors.white),
      tooltip: 'Maç Ekle (Admin)',
      onPressed: () => _showAddMatchDialog(),
    );
  }

  void _showAddMatchDialog() {
    final jsonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text('Maç Ekle (Admin)', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              Text(
                'JSON formatında maç bilgilerini girin:',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: jsonController,
                  maxLines: null,
                  expands: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '''[
  {
    "evSahibi": "Kocaelispor",
    "deplasman": "Galatasaray",
    "tarih": "2025-08-15T21:00:00Z",
    "saat": "21:00",
    "lig": "Süper Lig",
    "stadyum": "Kocaeli Büyükşehir Stadı",
    "evSahibiLogo": "https://...",
    "deplasmanLogo": "https://...",
    "skor": null
  }
]''',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade600),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primaryGreen),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (jsonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('JSON verisi boş olamaz'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                final parsed = jsonDecode(jsonController.text);
                List<dynamic> matches = parsed is List ? parsed : [parsed];

                for (var match in matches) {
                  final Map<String, dynamic> matchData = Map<String, dynamic>.from(match);

                  // Tarih string'ini Timestamp'e çevir
                  if (matchData['tarih'] is String) {
                    final dateTime = DateTime.parse(matchData['tarih']);
                    matchData['tarih'] = Timestamp.fromDate(dateTime);
                  }

                  await FirebaseFirestore.instance.collection('maclar').add(matchData);
                }

                await AdminService.logAdminActivity(
                  action: 'MATCH_ADDED',
                  targetType: 'MATCH',
                  details: {'matchCount': matches.length},
                );

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${matches.length} maç başarıyla eklendi!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('JSON format hatası: $e'),
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
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: widget.isKocaelisporTheme ? AppTheme.primaryGreen : AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }
}