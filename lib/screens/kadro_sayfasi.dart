// lib/screens/kadro_sayfasi.dart - Modern Pozisyonlu Tasarım
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';
import '../services/admin_service.dart';
import '../services/analytics_service.dart';
import 'foto_detay_sayfasi.dart';

class KadroSayfasi extends StatefulWidget {
  const KadroSayfasi({super.key});

  @override
  State<KadroSayfasi> createState() => _KadroSayfasiState();
}

class _KadroSayfasiState extends State<KadroSayfasi> with SingleTickerProviderStateMixin {
  bool _isAdmin = false;
  bool _isCheckingAdmin = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Pozisyon renkleri
  final Map<String, Color> _positionColors = {
    'Kaleci': const Color(0xFF4CAF50),
    'Defans': const Color(0xFF2196F3),
    'Orta Saha': const Color(0xFFFF9800),
    'Forvet': const Color(0xFFF44336),
    'Goalkeeper': const Color(0xFF4CAF50),
    'Defender': const Color(0xFF2196F3),
    'Midfielder': const Color(0xFFFF9800),
    'Forward': const Color(0xFFF44336),
  };

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
    AnalyticsService.logViewTeam();
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

  String _normalizePosition(String position) {
    final pos = position.toLowerCase().trim();
    if (pos.contains('kaleci') || pos.contains('goalkeeper') || pos.contains('gk')) {
      return 'Kaleci';
    } else if (pos.contains('defans') || pos.contains('defender') || pos.contains('def')) {
      return 'Defans';
    } else if (pos.contains('orta') || pos.contains('midfielder') || pos.contains('mid')) {
      return 'Orta Saha';
    } else if (pos.contains('forvet') || pos.contains('forward') || pos.contains('striker')) {
      return 'Forvet';
    }
    return 'Orta Saha'; // Varsayılan
  }

  Color _getPositionColor(String position) {
    final normalizedPos = _normalizePosition(position);
    return _positionColors[normalizedPos] ?? AppTheme.primaryGreen;
  }

  Map<String, List<QueryDocumentSnapshot>> _groupPlayersByPosition(List<QueryDocumentSnapshot> docs) {
    final Map<String, List<QueryDocumentSnapshot>> grouped = {
      'Kaleci': [],
      'Defans': [],
      'Orta Saha': [],
      'Forvet': [],
    };

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final position = data['pozisyon']?.toString() ?? 'Orta Saha';
      final normalizedPos = _normalizePosition(position);
      grouped[normalizedPos]!.add(doc);
    }

    // Her pozisyonu forma numarasına göre sırala
    grouped.forEach((key, value) {
      value.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aNum = aData['formaNo'] as int? ?? 999;
        final bNum = bData['formaNo'] as int? ?? 999;
        return aNum.compareTo(bNum);
      });
    });

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: const CustomAppBar(
        title: "Takım Kadrosu",
      ),
      floatingActionButton: _isAdmin ? _buildFAB() : null,
      body: Column(
        children: [
          // Admin kontrol çubuğu
          if (_isCheckingAdmin) _buildLoadingBar(),
          if (!_isCheckingAdmin && _isAdmin) _buildAdminBar(),

          // Kadro içeriği
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Takım')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildErrorWidget(snapshot.error.toString());
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingWidget();
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyWidget();
                }

                final groupedPlayers = _groupPlayersByPosition(snapshot.data!.docs);
                return _buildPositionsList(groupedPlayers);
              },
            ),
          ),
        ],
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
              'Yönetici modundasınız - Oyuncuları yönetebilirsiniz',
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

  Widget _buildPositionsList(Map<String, List<QueryDocumentSnapshot>> groupedPlayers) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Her pozisyon için section oluştur
          ...groupedPlayers.entries.where((entry) => entry.value.isNotEmpty).map((entry) {
            return _buildPositionSection(entry.key, entry.value);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPositionSection(String position, List<QueryDocumentSnapshot> players) {
    final color = _getPositionColor(position);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pozisyon başlığı
        Container(
          margin: const EdgeInsets.only(bottom: 16, top: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                _getPositionIcon(position),
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                position,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${players.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Oyuncu kartları - 2 sütunlu grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: players.length,
          itemBuilder: (context, index) {
            final doc = players[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildModernPlayerCard(data, doc.id, color);
          },
        ),

        const SizedBox(height: 24),
      ],
    );
  }

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

  Widget _buildModernPlayerCard(Map<String, dynamic> data, String docId, Color positionColor) {
    final playerName = data['isim'] ?? 'Bilinmeyen';
    final playerNumber = data['formaNo'] ?? 0;
    final playerPhoto = data['fotoUrl'] ?? '';
    final flagUrl = data['bayrakUrl'] ?? '';

    return GestureDetector(
      onTap: () {
        AnalyticsService.logViewPlayer(playerName, playerNumber);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FotoDetaySayfasi(
              fotoUrl: playerPhoto.isNotEmpty ? playerPhoto : 'https://via.placeholder.com/300',
              oyuncuAdi: playerName,
              pozisyon: data['pozisyon'] ?? 'Pozisyon Yok',
              formaNo: playerNumber,
            ),
          ),
        );
      },
      onLongPress: _isAdmin ? () => _showAdminOptions(docId, data) : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Admin etiketi
            if (_isAdmin)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Düzenlemek için uzun basın',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Oyuncu fotoğrafı ve forma numarası
                    Expanded(
                      flex: 3,
                      child: Stack(
                        children: [
                          // Ana fotoğraf
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  positionColor.withOpacity(0.1),
                                  positionColor.withOpacity(0.3),
                                ],
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: playerPhoto.isNotEmpty
                                  ? Hero(
                                tag: 'player_$playerNumber',
                                child: Image.network(
                                  playerPhoto,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildPlaceholderImage(positionColor);
                                  },
                                ),
                              )
                                  : _buildPlaceholderImage(positionColor),
                            ),
                          ),

                          // Forma numarası (sol üst)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: positionColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
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
                          ),

                          // Bayrak (sağ üst)
                          if (flagUrl.isNotEmpty)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 28,
                                height: 20,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    flagUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade300,
                                        child: const Icon(
                                          Icons.flag,
                                          size: 12,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),

                          // Admin düzenleme ikonu
                          if (_isAdmin)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade600,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Oyuncu adı
                    Text(
                      playerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        size: 48,
        color: Colors.white.withOpacity(0.8),
      ),
    );
  }

  // Admin seçenekleri modalı
  void _showAdminOptions(String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Oyuncu İşlemleri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
            const SizedBox(height: 16),

            // Düzenle
            ListTile(
              leading: Icon(Icons.edit, color: Colors.blue.shade600),
              title: const Text('Oyuncuyu Düzenle'),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(docId, data);
              },
            ),

            // Sil
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red.shade600),
              title: const Text('Oyuncuyu Sil'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(docId, data);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(String docId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => OyuncuDuzenleDialog(
        oyuncuId: docId,
        oyuncu: data,
      ),
    );
  }

  void _confirmDelete(String docId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Oyuncuyu Sil'),
        content: Text('\"${data['isim'] ?? 'Bu oyuncu'}\" adlı oyuncuyu silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePlayer(docId, data);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePlayer(String docId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection('Takım').doc(docId).delete();

      await AdminService.logAdminActivity(
        action: 'PLAYER_DELETED',
        targetType: 'PLAYER',
        targetId: docId,
        details: {
          'playerName': data['isim'],
          'playerNumber': data['formaNo'],
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Oyuncu başarıyla silindi'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Oyuncu silinemedi: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
          ),
          SizedBox(height: 16),
          Text('Kadro yükleniyor...'),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Henüz oyuncu eklenmemiş'),
          if (_isAdmin) ...[
            const SizedBox(height: 8),
            const Text('Yeni oyuncu eklemek için + butonuna basın'),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Hata oluştu: $error'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton(
      backgroundColor: AppTheme.primaryGreen,
      child: const Icon(Icons.add, color: Colors.white),
      tooltip: 'Oyuncu Ekle (Admin)',
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => const OyuncuEkleDialog(),
        );
      },
    );
  }
}

// Oyuncu Ekleme Dialog'u (basitleştirilmiş)
class OyuncuEkleDialog extends StatefulWidget {
  const OyuncuEkleDialog({super.key});

  @override
  State<OyuncuEkleDialog> createState() => _OyuncuEkleDialogState();
}

class _OyuncuEkleDialogState extends State<OyuncuEkleDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Oyuncu Ekle (Admin)"),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: '''[
  {
    "isim": "Ali Veli",
    "formaNo": 7,
    "pozisyon": "Orta Saha",
    "fotoUrl": "https://...",
    "bayrakUrl": "https://..."
  }
]''',
                border: OutlineInputBorder(),
                labelText: 'JSON Formatında Oyuncu Listesi',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("İptal"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () async {
            // Oyuncu ekleme logic buraya
            Navigator.pop(context);
          },
          child: const Text("Ekle"),
        ),
      ],
    );
  }
}

// Oyuncu Düzenleme Dialog'u (basitleştirilmiş)
class OyuncuDuzenleDialog extends StatefulWidget {
  final String oyuncuId;
  final Map<String, dynamic> oyuncu;

  const OyuncuDuzenleDialog({
    super.key,
    required this.oyuncuId,
    required this.oyuncu,
  });

  @override
  State<OyuncuDuzenleDialog> createState() => _OyuncuDuzenleDialogState();
}

class _OyuncuDuzenleDialogState extends State<OyuncuDuzenleDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Oyuncu Düzenle"),
      content: const Text("Düzenleme formu buraya gelecek"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("İptal"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Güncelle"),
        ),
      ],
    );
  }
}