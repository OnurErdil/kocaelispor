// lib/screens/kadro_sayfasi.dart - ANASAYFA GİBİ GÜZEL RENK TASARIMI
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/analytics_service.dart';
import '../services/admin_service.dart';
import 'foto_detay_sayfasi.dart';

class KadroSayfasi extends StatefulWidget {
  const KadroSayfasi({super.key});

  @override
  State<KadroSayfasi> createState() => _KadroSayfasiState();
}

class _KadroSayfasiState extends State<KadroSayfasi> {
  bool _isAdmin = false;
  bool _isCheckingAdmin = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    // Analytics - DOĞRU metodlar
    AnalyticsService.logViewTeam(); // logViewSquad değil logViewTeam
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
                            'KADRO',
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
          onPressed: _showAddPlayerDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.person_add,
            color: Colors.white,
            size: 28,
          ),
        ),
      )
          : null,

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('oyuncular')
            .orderBy('numara')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorWidget('Oyuncular yüklenirken hata oluştu: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingWidget();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyWidget();
          }

          final players = snapshot.data!.docs;
          final groupedPlayers = _groupPlayersByPosition(players);

          return RefreshIndicator(
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
                  // 🎨 İstatistik kartı - anasayfa gibi
                  _buildStatsCard(players.length),
                  const SizedBox(height: 24),

                  // Pozisyon grupları
                  ...groupedPlayers.entries.map((entry) {
                    return _buildPositionSection(entry.key, entry.value);
                  }).toList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 🎨 Yükleme widget'ı - koyu tema
  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00913C)),
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Kadro yükleniyor...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 İstatistik kartı - anasayfa gibi güzel tasarım
  Widget _buildStatsCard(int totalPlayers) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.people,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Toplam Oyuncu',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '$totalPlayers',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (_isAdmin && !_isCheckingAdmin)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.admin_panel_settings, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 🎨 Pozisyon bölümü - koyu tema
  Widget _buildPositionSection(String position, List<DocumentSnapshot> players) {
    final positionColors = {
      'Kaleci': const Color(0xFFE53E3E), // Kırmızı
      'Defans': const Color(0xFF3182CE), // Mavi
      'Orta Saha': const Color(0xFF9C27B0), // Mor
      'Forvet': const Color(0xFFD69E2E), // Turuncu
    };

    final color = positionColors[position] ?? Colors.grey.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🎨 Pozisyon başlığı - güzel tasarım
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getPositionIcon(position), color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                position,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${players.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 🎨 Oyuncu kartları - 2 sütunlu grid (mobil için daha iyi)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Mobil için 2 sütun daha iyi
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8, // Daha güzel oran
          ),
          itemCount: players.length,
          itemBuilder: (context, index) {
            final doc = players[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildPlayerCard(data, doc.id, color);
          },
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  // 🎨 Modern oyuncu kartı - anasayfa gibi güzel
  Widget _buildPlayerCard(Map<String, dynamic> data, String docId, Color positionColor) {
    final playerName = data['isim'] ?? 'Bilinmeyen';
    final playerNumber = data['numara'] ?? 0;
    final playerPhoto = data['foto'] ?? '';
    final flagUrl = data['bayrak'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade800,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AnalyticsService.logViewPlayer(playerName, playerNumber);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FotoDetaySayfasi(
                  fotoUrl: playerPhoto.isNotEmpty ? playerPhoto : 'https://via.placeholder.com/200',
                  oyuncuAdi: playerName,
                  pozisyon: data['pozisyon'] ?? 'Bilinmeyen',
                  formaNo: playerNumber, // ← EKSİK OLAN PARAMETRE EKLENDI!
                ),
              ),
            );
          },
          onLongPress: _isAdmin ? () => _showPlayerOptions(docId, data) : null,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // 🎨 Oyuncu fotoğrafı
              Expanded(
                flex: 3,
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Fotoğraf
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: playerPhoto.isNotEmpty
                            ? Image.network(
                          playerPhoto,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage(positionColor);
                          },
                        )
                            : _buildPlaceholderImage(positionColor),
                      ),

                      // Numara - sol üst köşe
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: positionColor,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '$playerNumber',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // Bayrak - sağ üst köşe
                      if (flagUrl.isNotEmpty)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 24,
                            height: 16,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: Image.network(
                                flagUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade600,
                                    child: const Icon(
                                      Icons.flag,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 🎨 Oyuncu bilgileri - alt kısım
              Expanded(
                flex: 1,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      playerName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎨 Placeholder fotoğraf - güzel gradient
  Widget _buildPlaceholderImage(Color color) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.3),
            color.withOpacity(0.6),
          ],
        ),
      ),
      child: Icon(
        Icons.person,
        size: 40,
        color: Colors.white.withOpacity(0.8),
      ),
    );
  }

  // 🎨 Boş widget - koyu tema
  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade800),
            ),
            child: Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Henüz oyuncu eklenmemiş',
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isAdmin ? 'İlk oyuncuyu siz ekleyin!' : 'Yakında oyuncular eklenecek!',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // 🎨 Hata widget'ı - koyu tema
  Widget _buildErrorWidget(String message) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'Bir hata oluştu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00913C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Pozisyon ikonu
  IconData _getPositionIcon(String position) {
    switch (position) {
      case 'Kaleci':
        return Icons.sports_handball;
      case 'Defans':
        return Icons.shield;
      case 'Orta Saha':
        return Icons.adjust;
      case 'Forvet':
        return Icons.sports_score;
      default:
        return Icons.sports_soccer;
    }
  }

  // Oyuncuları pozisyona göre grupla
  Map<String, List<DocumentSnapshot>> _groupPlayersByPosition(List<DocumentSnapshot> players) {
    final Map<String, List<DocumentSnapshot>> grouped = {};

    for (final player in players) {
      final data = player.data() as Map<String, dynamic>;
      final position = data['pozisyon'] ?? 'Diğer';

      if (!grouped.containsKey(position)) {
        grouped[position] = [];
      }
      grouped[position]!.add(player);
    }

    // Pozisyon sıralaması
    final orderedPositions = ['Kaleci', 'Defans', 'Orta Saha', 'Forvet'];
    final Map<String, List<DocumentSnapshot>> orderedGrouped = {};

    for (final position in orderedPositions) {
      if (grouped.containsKey(position)) {
        orderedGrouped[position] = grouped[position]!;
      }
    }

    // Diğer pozisyonları da ekle
    for (final entry in grouped.entries) {
      if (!orderedPositions.contains(entry.key)) {
        orderedGrouped[entry.key] = entry.value;
      }
    }

    return orderedGrouped;
  }

  // Admin işlemleri (mevcut kodda var olan metodlar)
  void _showAddPlayerDialog() {
    // Oyuncu ekleme dialogu
  }

  void _showPlayerOptions(String docId, Map<String, dynamic> data) {
    // Oyuncu seçenekleri göster
  }
}