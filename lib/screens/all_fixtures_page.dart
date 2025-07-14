// lib/screens/all_fixtures_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

class AllFixturesPage extends StatefulWidget {
  const AllFixturesPage({super.key});

  @override
  State<AllFixturesPage> createState() => _AllFixturesPageState();
}

class _AllFixturesPageState extends State<AllFixturesPage> with TickerProviderStateMixin {
  bool _isAdmin = false;
  bool _isCheckingAdmin = true; // ✅ Yükleme durumu eklendi
  String _selectedFilter = 'Tümü'; // Tümü, Yaklaşan, Oynanan

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Admin durumu kontrolü - GÜÇLENDIRILDI
  Future<void> _checkAdminStatus() async {
    setState(() {
      _isCheckingAdmin = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      print("🔍 All Fixtures - User: ${user?.email}"); // Debug

      if (user != null) {
        // Birden fazla deneme yap
        for (int i = 0; i < 3; i++) {
          final adminDoc = await FirebaseFirestore.instance
              .collection('admins')
              .doc(user.uid)
              .get();

          print("🔍 All Fixtures - Admin doc exists (attempt ${i+1}): ${adminDoc.exists}"); // Debug

          if (adminDoc.exists) {
            setState(() {
              _isAdmin = true;
              _isCheckingAdmin = false;
            });
            print("✅ All Fixtures - Admin confirmed!"); // Debug
            return;
          }

          // Kısa bekleme
          await Future.delayed(const Duration(milliseconds: 500));
        }

        // 3 deneme sonrası admin değil
        setState(() {
          _isAdmin = false;
          _isCheckingAdmin = false;
        });
        print("❌ All Fixtures - Not admin after 3 attempts"); // Debug
      } else {
        print("🔍 All Fixtures - No user logged in"); // Debug
        setState(() {
          _isAdmin = false;
          _isCheckingAdmin = false;
        });
      }
    } catch (e) {
      print("❌ All Fixtures - Admin check error: $e"); // Debug
      setState(() {
        _isAdmin = false;
        _isCheckingAdmin = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debug bilgisi
    print("🎯 All Fixtures Build - _isAdmin: $_isAdmin");

    return Scaffold(
      appBar: AppBar(
        title: Text(_isAdmin ? 'Tüm Fikstür (Admin)' : 'Tüm Fikstür'), // Debug için title'da göster
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F0F0F), Color(0xFF2D2D2D)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      floatingActionButton: _isAdmin ? _buildFAB() : null, // ✅ FAB eklendi
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
            // Yükleme durumu - ✅ EKLENDI
            if (_isCheckingAdmin)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.blue.withOpacity(0.3),
                child: const Text(
                  'Admin durumu kontrol ediliyor...',
                  style: TextStyle(color: Colors.white),
                ),
              ),

            // Admin bar - ✅ Eklendi
            if (!_isCheckingAdmin && _isAdmin) _buildAdminBar(),

            // Debug container - GEÇİCİ
            if (!_isCheckingAdmin)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.purple.withOpacity(0.3),
                child: Text(
                  'DEBUG: Admin Status = $_isAdmin | User: ${FirebaseAuth.instance.currentUser?.email ?? "None"}',
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),

            // Filtre seçenekleri
            _buildFilterButtons(),

            // Maç listesi
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildMatchList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Admin bar - ✅ YENİ FONKSİYON
  Widget _buildAdminBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: AppTheme.primaryGreen.withOpacity(0.2),
      child: Row(
        children: [
          Icon(Icons.admin_panel_settings, color: AppTheme.primaryGreen),
          const SizedBox(width: 8),
          const Text(
            'Admin modunda - Maç ekleyebilir, düzenleyebilir ve silebilirsiniz',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  // Filtre butonları
  Widget _buildFilterButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterButton('Tümü'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterButton('Yaklaşan'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFilterButton('Oynanan'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String filter) {
    final isSelected = _selectedFilter == filter;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? AppTheme.primaryGreen
            : const Color(0xFF2D2D2D),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected
                ? AppTheme.primaryGreen
                : Colors.grey.withOpacity(0.3),
          ),
        ),
      ),
      child: Text(
        filter,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  // Maç listesi - DÜZELTİLDİ
  Widget _buildMatchList() {
    if (_selectedFilter == 'Oynanan') {
      // Oynanan maçlar için özel stream
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('maclar')
            .orderBy('tarih', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorWidget('Maçlar yüklenemedi');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyWidget();
          }

          // Sadece skoru girilmiş maçları filtrele
          final finishedMatches = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final skor = data['skor'];

            if (skor == null) return false;

            if (skor is Map) {
              final evSahibiSkor = skor['ev_sahibi'] ?? skor['evSahibi'];
              final deplasmanSkor = skor['deplasman'] ?? skor['rakip'];
              return evSahibiSkor != null && deplasmanSkor != null;
            }

            if (skor is String) {
              return skor.isNotEmpty && skor.contains('-');
            }

            return false;
          }).toList();

          if (finishedMatches.isEmpty) {
            return _buildEmptyWidget();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: finishedMatches.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildMatchCard(finishedMatches[index]),
              );
            },
          );
        },
      );
    } else {
      // Diğer filtreler için normal stream
      return StreamBuilder<QuerySnapshot>(
        stream: _getFilteredMatches(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorWidget('Maçlar yüklenemedi');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyWidget();
          }

          final matches = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildMatchCard(matches[index]),
              );
            },
          );
        },
      );
    }
  }

  // Filtrelenmiş maçları getir - BASİTLEŞTİRİLDİ
  Stream<QuerySnapshot> _getFilteredMatches() {
    final now = Timestamp.now();

    switch (_selectedFilter) {
      case 'Yaklaşan':
        return FirebaseFirestore.instance
            .collection('maclar')
            .where('tarih', isGreaterThan: now)
            .orderBy('tarih', descending: false)
            .snapshots();
      default: // Tümü
        return FirebaseFirestore.instance
            .collection('maclar')
            .orderBy('tarih', descending: false)
            .snapshots();
    }
  }

  // Maç kartı
  Widget _buildMatchCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = data['tarih'] as Timestamp?;

    // Farklı veri formatlarını destekle
    final homeTeam = data['ev_sahibi'] ?? data['evSahibi'] ?? 'Kocaelispor';
    final awayTeam = data['deplasman'] ?? data['rakip'] ?? 'Rakip';
    final homeLogoUrl = data['ev_sahibi_logo'] ?? data['evSahibiLogo'];
    final awayLogoUrl = data['deplasman_logo'] ?? data['rakipLogo'];
    final stad = data['stad'] ?? data['lokasyon'] ?? '';

    // Skor bilgilerini al
    final skorData = data['skor'];
    dynamic homeScore, awayScore;

    if (skorData is Map) {
      homeScore = skorData['ev_sahibi'] ?? skorData['evSahibi'];
      awayScore = skorData['deplasman'] ?? skorData['rakip'];
    } else if (skorData is String && skorData.contains('-')) {
      final parts = skorData.split('-');
      if (parts.length == 2) {
        homeScore = parts[0].trim();
        awayScore = parts[1].trim();
      }
    }

    final matchDate = timestamp?.toDate() ?? DateTime.now();
    final isFinished = homeScore != null && awayScore != null;
    final isPast = matchDate.isBefore(DateTime.now());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFinished
              ? Colors.green.withOpacity(0.5)
              : isPast
              ? Colors.red.withOpacity(0.5)
              : Colors.orange.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Maç bilgileri
          Row(
            children: [
              // Ev sahibi takım
              Expanded(
                child: Column(
                  children: [
                    _buildTeamLogo(homeLogoUrl, homeTeam),
                    const SizedBox(height: 8),
                    Text(
                      homeTeam,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Skor veya VS
              Expanded(
                child: Column(
                  children: [
                    if (isFinished)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$homeScore - $awayScore',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isPast
                              ? Colors.red.withOpacity(0.2)
                              : Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isPast ? 'ERTELENDİ' : 'VS',
                          style: TextStyle(
                            color: isPast ? Colors.red : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: isPast ? 10 : 18,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '${matchDate.day}/${matchDate.month}/${matchDate.year}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${matchDate.hour}:${matchDate.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Deplasman takım
              Expanded(
                child: Column(
                  children: [
                    _buildTeamLogo(awayLogoUrl, awayTeam),
                    const SizedBox(height: 8),
                    Text(
                      awayTeam,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Stadyum bilgisi
          if (stad.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.location_on,
                  color: Colors.grey,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  stad,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],

          // Admin butonları - ✅ DÜZELTİLDİ VE DEBUG EKLENDİ
          if (_isAdmin) ...[
            const SizedBox(height: 16),

            // Debug container - GEÇİCİ
            Container(
              padding: const EdgeInsets.all(4),
              color: Colors.orange.withOpacity(0.3),
              child: Text(
                'ADMIN BUTTONS: isAdmin=$_isAdmin, isFinished=$isFinished, isPast=$isPast',
                style: const TextStyle(color: Colors.white, fontSize: 8),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Skor Gir butonu (sadece henüz bitmemiş ve geçmemiş maçlarda)
                if (!isFinished && !isPast)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showScoreDialog(doc.id, homeTeam, awayTeam),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Skor Gir', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                if (!isFinished && !isPast) const SizedBox(width: 8),

                // Düzenle butonu (her zaman)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showEditDialog(doc),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Düzenle', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),

                // Sil butonu (her zaman)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showDeleteDialog(doc.id, homeTeam, awayTeam),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Sil', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Admin değilse debug mesajı
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.red.withOpacity(0.3),
              child: const Text(
                'NOT ADMIN - No buttons shown',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Team logo widget
  Widget _buildTeamLogo(String? logoUrl, String teamName) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade600),
      ),
      child: logoUrl != null && logoUrl.isNotEmpty
          ? ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          logoUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.sports_soccer,
              color: Colors.grey.shade400,
              size: 25,
            );
          },
        ),
      )
          : Icon(
        Icons.sports_soccer,
        color: Colors.grey.shade400,
        size: 25,
      ),
    );
  }

  // Error widget
  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Empty widget
  Widget _buildEmptyWidget() {
    String message;
    IconData icon;

    switch (_selectedFilter) {
      case 'Yaklaşan':
        message = 'Yaklaşan maç bulunmuyor';
        icon = Icons.schedule;
        break;
      case 'Oynanan':
        message = 'Henüz oynanmış maç bulunmuyor';
        icon = Icons.sports_soccer;
        break;
      default:
        message = 'Henüz maç bulunmuyor';
        icon = Icons.list;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.grey,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 16,
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
            Text(
              '$homeTeam - $awayTeam',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: homeController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: homeTeam,
                      labelStyle: const TextStyle(color: Colors.grey),
                      border: const OutlineInputBorder(),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.primaryGreen),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: awayController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: awayTeam,
                      labelStyle: const TextStyle(color: Colors.grey),
                      border: const OutlineInputBorder(),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: AppTheme.primaryGreen),
                      ),
                    ),
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
              final homeScore = homeController.text.trim();
              final awayScore = awayController.text.trim();

              if (homeScore.isNotEmpty && awayScore.isNotEmpty) {
                try {
                  await FirebaseFirestore.instance
                      .collection('maclar')
                      .doc(docId)
                      .update({
                    'skor': {
                      'ev_sahibi': int.parse(homeScore),
                      'deplasman': int.parse(awayScore),
                    }
                  });

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Maç sonucu kaydedildi!'),
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
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Maç düzenleme dialog'u
  void _showEditDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final homeTeamController = TextEditingController(text: data['ev_sahibi'] ?? data['evSahibi'] ?? '');
    final awayTeamController = TextEditingController(text: data['deplasman'] ?? data['rakip'] ?? '');
    final stadController = TextEditingController(text: data['stad'] ?? data['lokasyon'] ?? '');
    final homeLogoController = TextEditingController(text: data['ev_sahibi_logo'] ?? data['evSahibiLogo'] ?? '');
    final awayLogoController = TextEditingController(text: data['deplasman_logo'] ?? data['rakipLogo'] ?? '');

    final timestamp = data['tarih'] as Timestamp?;
    DateTime selectedDate = timestamp?.toDate() ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);

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
              // Ev sahibi takım
              TextFormField(
                controller: homeTeamController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Ev Sahibi Takım',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: const OutlineInputBorder(),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryGreen),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Deplasman takım
              TextFormField(
                controller: awayTeamController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Deplasman Takım',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: const OutlineInputBorder(),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryGreen),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Stadyum
              TextFormField(
                controller: stadController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Stadyum',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: const OutlineInputBorder(),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryGreen),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Ev sahibi logo
              TextFormField(
                controller: homeLogoController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Ev Sahibi Logo URL',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: const OutlineInputBorder(),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryGreen),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Deplasman logo
              TextFormField(
                controller: awayLogoController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Deplasman Logo URL',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: const OutlineInputBorder(),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryGreen),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tarih seçici
              ListTile(
                title: const Text(
                  'Maç Tarihi',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.calendar_today, color: Colors.white),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: AppTheme.primaryGreen,
                            surface: const Color(0xFF2D2D2D),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (date != null) {
                    selectedDate = date;
                  }
                },
              ),

              // Saat seçici
              ListTile(
                title: const Text(
                  'Maç Saati',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.access_time, color: Colors.white),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: AppTheme.primaryGreen,
                            surface: const Color(0xFF2D2D2D),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (time != null) {
                    selectedTime = time;
                  }
                },
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
              final homeTeam = homeTeamController.text.trim();
              final awayTeam = awayTeamController.text.trim();
              final stad = stadController.text.trim();
              final homeLogo = homeLogoController.text.trim();
              final awayLogo = awayLogoController.text.trim();

              if (homeTeam.isNotEmpty && awayTeam.isNotEmpty) {
                try {
                  final matchDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );

                  await FirebaseFirestore.instance
                      .collection('maclar')
                      .doc(doc.id)
                      .update({
                    'ev_sahibi': homeTeam,
                    'deplasman': awayTeam,
                    'stad': stad.isNotEmpty ? stad : 'Belirtilmemiş',
                    'ev_sahibi_logo': homeLogo,
                    'deplasman_logo': awayLogo,
                    'tarih': Timestamp.fromDate(matchDateTime),
                    'guncelleme_tarihi': Timestamp.now(),
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
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lütfen takım isimlerini girin!'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            child: const Text('Güncelle', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Maç silme dialog'u
  void _showDeleteDialog(String docId, String homeTeam, String awayTeam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D2D),
        title: const Text(
          'Maçı Sil',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '$homeTeam - $awayTeam maçını silmek istediğinizden emin misiniz?',
          style: const TextStyle(color: Colors.white),
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
            ),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Maç ekleme dialog'u
  void _showAddMatchDialog() {
    final homeTeamController = TextEditingController();
    final awayTeamController = TextEditingController();
    final stadController = TextEditingController();
    final homeLogoController = TextEditingController();
    final awayLogoController = TextEditingController();

    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

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
              // Ev sahibi takım
              TextFormField(
                controller: homeTeamController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Ev Sahibi Takım',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: const OutlineInputBorder(),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryGreen),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Deplasman takım
              TextFormField(
                controller: awayTeamController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Deplasman Takım',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: const OutlineInputBorder(),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryGreen),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Stadyum
              TextFormField(
                controller: stadController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Stadyum',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: const OutlineInputBorder(),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryGreen),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Ev sahibi logo
              TextFormField(
                controller: homeLogoController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Ev Sahibi Logo URL',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: const OutlineInputBorder(),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryGreen),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Deplasman logo
              TextFormField(
                controller: awayLogoController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Deplasman Logo URL',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: const OutlineInputBorder(),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.primaryGreen),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tarih seçici
              ListTile(
                title: const Text(
                  'Maç Tarihi',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.calendar_today, color: Colors.white),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: AppTheme.primaryGreen,
                            surface: const Color(0xFF2D2D2D),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (date != null) {
                    selectedDate = date;
                  }
                },
              ),

              // Saat seçici
              ListTile(
                title: const Text(
                  'Maç Saati',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.grey),
                ),
                trailing: const Icon(Icons.access_time, color: Colors.white),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: AppTheme.primaryGreen,
                            surface: const Color(0xFF2D2D2D),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (time != null) {
                    selectedTime = time;
                  }
                },
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
              final homeTeam = homeTeamController.text.trim();
              final awayTeam = awayTeamController.text.trim();
              final stad = stadController.text.trim();
              final homeLogo = homeLogoController.text.trim();
              final awayLogo = awayLogoController.text.trim();

              if (homeTeam.isNotEmpty && awayTeam.isNotEmpty) {
                try {
                  final matchDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );

                  await FirebaseFirestore.instance.collection('maclar').add({
                    'ev_sahibi': homeTeam,
                    'deplasman': awayTeam,
                    'stad': stad.isNotEmpty ? stad : 'Belirtilmemiş',
                    'ev_sahibi_logo': homeLogo,
                    'deplasman_logo': awayLogo,
                    'tarih': Timestamp.fromDate(matchDateTime),
                    'skor': null,
                    'olusturma_tarihi': Timestamp.now(),
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
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Lütfen takım isimlerini girin!'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            child: const Text('Ekle', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}