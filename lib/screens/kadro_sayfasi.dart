// lib/screens/kadro_sayfasi.dart - TAM VE EKSİKSİZ KOD

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_app_bar.dart';
import '../services/admin_service.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';
import 'foto_detay_sayfasi.dart';

class KadroSayfasi extends StatefulWidget {
  const KadroSayfasi({super.key});

  @override
  State<KadroSayfasi> createState() => _KadroSayfasiState();
}

class _KadroSayfasiState extends State<KadroSayfasi>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Admin kontrolü için
  bool _isAdmin = false;
  bool _isCheckingAdmin = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _checkAdminStatus();

    // Analytics
    AnalyticsService.logViewTeam();
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
    // ✅ DEBUG: Auth durumunu kontrol et
    final user = FirebaseAuth.instance.currentUser;
    print('🔍 Current user: ${user?.email}');
    print('🔍 User ID: ${user?.uid}');
    print('🔍 Email verified: ${user?.emailVerified}');

    return Scaffold(
      backgroundColor: Colors.black, // ✅ Siyah arka plan
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Icon(Icons.people, color: Colors.green.shade400, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Takım Kadrosu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        leading: IconButton( // ✅ Geri buton düzeltildi
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isCheckingAdmin && _isAdmin)
            IconButton(
              onPressed: _showAddPlayerDialog,
              icon: Icon(
                Icons.add,
                color: Colors.green.shade400,
              ),
              tooltip: 'Oyuncu Ekle',
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black,
                Colors.grey.shade900,
                Colors.black,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('oyuncular') // ✅ Doğru koleksiyon adı
                .orderBy('numara')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingWidget();
              }

              if (snapshot.hasError) {
                return _buildErrorWidget('Veriler yüklenemedi: ${snapshot.error}');
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyWidget();
              }

              final players = snapshot.data!.docs;

              // Pozisyonlara göre grupla
              final playersByPosition = _groupPlayersByPosition(players);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Başlık ve istatistik
                    _buildHeaderStats(players.length),
                    const SizedBox(height: 24),

                    // Pozisyonlara göre oyuncular
                    ...playersByPosition.entries.map((entry) {
                      return _buildPositionSection(entry.key, entry.value);
                    }).toList(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Başlık ve istatistikler
  Widget _buildHeaderStats(int totalPlayers) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.shade700,
            Colors.green.shade800,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade700.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.sports_soccer,
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
                color: Colors.yellow.shade600,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.admin_panel_settings, size: 16, color: Colors.black),
                  SizedBox(width: 4),
                  Text(
                    'Admin',
                    style: TextStyle(
                      color: Colors.black,
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

  // Pozisyon bölümü
  Widget _buildPositionSection(String position, List<DocumentSnapshot> players) {
    final positionColors = {
      'Kaleci': Colors.orange.shade600,
      'Defans': Colors.blue.shade600,
      'Orta Saha': Colors.purple.shade600,
      'Forvet': Colors.red.shade600,
    };

    final color = positionColors[position] ?? Colors.grey.shade600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pozisyon başlığı
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 1),
          ),
          child: Row(
            children: [
              Icon(_getPositionIcon(position), color: color, size: 24),
              const SizedBox(width: 12),
              Text(
                position,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
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

        // Oyuncu kartları - 4 sütunlu grid ✅
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, // ✅ 4 kart her satırda
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.7, // ✅ Daha kompakt kartlar
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

  // Modern oyuncu kartı ✅
  Widget _buildPlayerCard(Map<String, dynamic> data, String docId, Color positionColor) {
    final playerName = data['isim'] ?? 'Bilinmeyen';
    final playerNumber = data['numara'] ?? 0;
    final playerPhoto = data['foto'] ?? '';
    final flagUrl = data['bayrak'] ?? '';

    return GestureDetector(
      onTap: () {
        AnalyticsService.logViewPlayer(playerName, playerNumber);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FotoDetaySayfasi(
              fotoUrl: playerPhoto.isNotEmpty ? playerPhoto : 'https://via.placeholder.com/200',
              oyuncuAdi: playerName,
              pozisyon: data['pozisyon'] ?? 'Pozisyon Yok',
              formaNo: playerNumber,
            ),
          ),
        );
      },
      onLongPress: _isAdmin ? () => _showPlayerOptions(docId, data) : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: positionColor.withOpacity(0.3), width: 1),
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
            // Fotoğraf bölümü
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.grey.shade800,
                ),
                child: Stack(
                  children: [
                    // Oyuncu fotoğrafı ✅ Küçük boyut
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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

                    // Forma numarası (sol üst)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: positionColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '$playerNumber',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Bayrak (sağ üst)
                    if (flagUrl.isNotEmpty)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 20,
                          height: 14,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: Image.network(
                              flagUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade400,
                                  child: const Icon(Icons.flag, size: 8, color: Colors.grey),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                    // Admin düzenleme ikonu
                    if (_isAdmin)
                      Positioned(
                        bottom: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _showPlayerOptions(docId, data),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade600,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // İsim bölümü
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: Text(
                    playerName,
                    style: const TextStyle(
                      fontSize: 12,
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
    );
  }

  // Placeholder fotoğraf
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
        size: 30,
        color: Colors.white.withOpacity(0.8),
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

    // Diğer pozisyonları ekle
    grouped.forEach((key, value) {
      if (!orderedPositions.contains(key)) {
        orderedGrouped[key] = value;
      }
    });

    return orderedGrouped;
  }

  // Admin seçenekleri modal
  void _showPlayerOptions(String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
            const SizedBox(height: 20),

            Text(
              data['isim'] ?? 'Oyuncu',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Düzenle butonu

            // Sil butonu
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red.shade400),
              title: const Text('Sil', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(docId, data);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Oyuncu ekleme dialog'u ✅
  // Oyuncu düzenleme dialog'u
  Future<void> _showAddPlayerDialog() async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController numberController = TextEditingController();
    final TextEditingController photoController = TextEditingController();
    final TextEditingController flagController = TextEditingController();
    String selectedPosition = 'Forvet';

    final positions = ['Kaleci', 'Defans', 'Orta Saha', 'Forvet'];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A), // Daha siyah
        title: const Text('Yeni Oyuncu Ekle', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Oyuncu Adı',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade600),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green.shade400),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: numberController,
                decoration: InputDecoration(
                  labelText: 'Forma Numarası',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade600),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green.shade400),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: selectedPosition,
                decoration: InputDecoration(
                  labelText: 'Pozisyon',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade600),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green.shade400),
                  ),
                ),
                dropdownColor: Colors.grey.shade800,
                style: const TextStyle(color: Colors.white),
                items: positions.map((position) {
                  return DropdownMenuItem(
                    value: position,
                    child: Text(position, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedPosition = value!;
                },
              ),
              const SizedBox(height: 16),

              TextField(
                controller: photoController,
                decoration: InputDecoration(
                  labelText: 'Fotoğraf URL (İsteğe Bağlı)',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade600),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green.shade400),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: flagController,
                decoration: InputDecoration(
                  labelText: 'Bayrak URL (İsteğe Bağlı)',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade600),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.green.shade400),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: Colors.grey.shade400)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final numberText = numberController.text.trim();
              final photo = photoController.text.trim();
              final flag = flagController.text.trim();

              if (name.isNotEmpty && numberText.isNotEmpty) {
                final number = int.tryParse(numberText);
                if (number != null) {
                  await _addPlayer(name, number, selectedPosition, photo, flag);
                  Navigator.pop(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
            ),
            child: const Text('Ekle', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Silme onayı ✅

  // Oyuncu ekleme fonksiyonu ✅
  Future<void> _addPlayer(String name, int number, String position, String? photo, String? flag) async {
    try {
      print('🔍 Oyuncu ekleniyor: $name, $number, $position');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ Kullanıcı giriş yapmamış');
        throw Exception('Giriş yapmalısınız');
      }

      print('🔍 User: ${user.email}');

      final playerData = {
        'isim': name,
        'numara': number,          // ← DOĞRU FIELD NAME
        'pozisyon': position,
        'foto': photo ?? '',       // ← DOĞRU FIELD NAME
        'bayrak': flag ?? '',      // ← DOĞRU FIELD NAME
        'olusturan': user.email,
        'olusturma_tarihi': Timestamp.now(),
      };

      print('🔍 Player data: $playerData');

      await FirebaseFirestore.instance
          .collection('oyuncular')
          .add(playerData);

      print('✅ Oyuncu başarıyla eklendi');

      // ✅ UI'yi zorla güncelle
      if (mounted) {
        setState(() {});
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ $name başarıyla eklendi!'),
          backgroundColor: const Color(0xFF00A651), // Kocaelispor yeşili
        ),
      );

    } catch (e) {
      print('❌ Oyuncu ekleme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Oyuncu güncelleme fonksiyonu ✅
  Future<void> _updatePlayer(String docId, String name, int number, String position, String photo, String flag) async {
    try {
      await FirebaseFirestore.instance.collection('oyuncular').doc(docId).update({
        'isim': name,
        'numara': number,
        'pozisyon': position,
        'foto': photo.isNotEmpty ? photo : null,
        'bayrak': flag.isNotEmpty ? flag : null,
        'guncellenmeTarihi': FieldValue.serverTimestamp(),
        'guncelleyen': FirebaseAuth.instance.currentUser?.email ?? 'Admin',
      });

      await AdminService.logAdminActivity(
        action: 'PLAYER_UPDATED',
        targetType: 'PLAYER',
        targetId: docId,
        details: {
          'playerName': name,
          'playerNumber': number,
          'position': position,
        },
      );

      AnalyticsService.logEditPlayer(name);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('$name başarıyla güncellendi'),
              ],
            ),
            backgroundColor: const Color(0xFF1B5E20),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Oyuncu güncellenemedi: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
  // Oyuncu silme fonksiyonu ✅
  Future<void> _deletePlayer(String docId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection('oyuncular').doc(docId).delete();

      await AdminService.logAdminActivity(
        action: 'PLAYER_DELETED',
        targetType: 'PLAYER',
        targetId: docId,
        details: {
          'playerName': data['isim'],
          'playerNumber': data['numara'],
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('${data['isim'] ?? 'Oyuncu'} başarıyla silindi'),
              ],
            ),
            backgroundColor: const Color(0xFF1B5E20),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Oyuncu silinemedi: $e'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Yükleniyor widget'ı
  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
          ),
          const SizedBox(height: 16),
          const Text(
            'Kadro yükleniyor...',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  // Boş widget'ı
  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey.shade600),
          const SizedBox(height: 16),
          const Text(
            'Henüz oyuncu eklenmemiş',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          if (_isAdmin) ...[
            const SizedBox(height: 8),
            Text(
              'Yeni oyuncu eklemek için + butonuna basın',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Hata widget'ı
  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          Text(
            'Hata oluştu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20), // Kocaelispor yeşili
            ),
            child: const Text('Tekrar Dene', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  Future<void> _showDeleteConfirmation(String docId, Map<String, dynamic> data) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A), // Daha siyah
        title: const Text('Oyuncu Sil', style: TextStyle(color: Colors.white)),
        content: Text(
          '"${data['isim'] ?? 'Bu oyuncu'}" adlı oyuncuyu silmek istediğinizden emin misiniz?',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: Colors.grey.shade400)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePlayer(docId, data);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  Future<void> _showEditPlayerDialog(String docId, Map<String, dynamic> currentData) async {
    final TextEditingController nameController = TextEditingController(text: currentData['isim'] ?? '');
    final TextEditingController numberController = TextEditingController(text: (currentData['numara'] ?? '').toString());
    final TextEditingController photoController = TextEditingController(text: currentData['foto'] ?? '');
    final TextEditingController flagController = TextEditingController(text: currentData['bayrak'] ?? '');
    String selectedPosition = currentData['pozisyon'] ?? 'Forvet';

    final positions = ['Kaleci', 'Defans', 'Orta Saha', 'Forvet'];

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A), // Kocaelispor siyahı
        title: const Text('Oyuncu Düzenle', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Oyuncu Adı',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade600),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1B5E20)), // Kocaelispor yeşili
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: numberController,
                decoration: InputDecoration(
                  labelText: 'Forma Numarası',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade600),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1B5E20)),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: selectedPosition,
                decoration: InputDecoration(
                  labelText: 'Pozisyon',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade600),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1B5E20)),
                  ),
                ),
                dropdownColor: Colors.grey.shade800,
                style: const TextStyle(color: Colors.white),
                items: positions.map((position) {
                  return DropdownMenuItem(
                    value: position,
                    child: Text(position, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedPosition = value!;
                },
              ),
              const SizedBox(height: 16),

              TextField(
                controller: photoController,
                decoration: InputDecoration(
                  labelText: 'Fotoğraf URL (İsteğe Bağlı)',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade600),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1B5E20)),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: flagController,
                decoration: InputDecoration(
                  labelText: 'Bayrak URL (İsteğe Bağlı)',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade600),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1B5E20)),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: Colors.grey.shade400)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final numberText = numberController.text.trim();
              final photo = photoController.text.trim();
              final flag = flagController.text.trim();

              if (name.isNotEmpty && numberText.isNotEmpty) {
                final number = int.tryParse(numberText);
                if (number != null) {
                  await _updatePlayer(docId, name, number, selectedPosition, photo, flag);
                  Navigator.pop(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20), // Kocaelispor yeşili
            ),
            child: const Text('Güncelle', style: TextStyle(color: Colors.white)),
          ),
          IconButton(
            icon: const Icon(Icons.bug_report, color: Colors.orange),
            onPressed: _testFirebaseConnection,
          ),
        ],
      ),
    );
  }
  Future<void> _testFirebaseConnection() async {
    try {
      print('🔍 Firebase bağlantısı test ediliyor...');

      // Test 1: Kullanıcı durumu
      final user = FirebaseAuth.instance.currentUser;
      print('🔍 User: ${user?.email}');

      // Test 2: Firestore okuma testi
      final testDoc = await FirebaseFirestore.instance
          .collection('oyuncular')
          .limit(1)
          .get();

      print('✅ Firestore okuma başarılı: ${testDoc.docs.length} dokuman');

      // Test 3: Firestore yazma testi
      await FirebaseFirestore.instance
          .collection('test_collection')
          .doc('test_doc')
          .set({
        'test': true,
        'timestamp': Timestamp.now(),
        'user': user?.email,
      });

      print('✅ Firestore yazma başarılı');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Firebase bağlantısı başarılı!'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      print('❌ Firebase test hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} // ← CLASS BURAS BURADA Bİ