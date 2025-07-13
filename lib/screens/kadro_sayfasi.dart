import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_app_bar.dart';
import 'foto_detay_sayfasi.dart'; // ✅ YENİ IMPORT

// Constants için ayrı dosya oluşturmanız önerilir
class AppColors {
  static const Color primary = Color(0xFF00913C);
  static const Color primaryDark = Color(0xFF006B2F);
  static const Color white = Colors.white;
  static const Color whiteTransparent = Colors.white70;
}

class KadroSayfasi extends StatelessWidget {
  const KadroSayfasi({super.key});

  @override
  Widget build(BuildContext context) {
    // Bu değeri gerçek auth sisteminden almalısınız
    const bool isAdmin = true;

    return Scaffold(
      appBar: const CustomAppBar(
        title: "Takım Kadrosu",
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Takım')
            .orderBy('formaNo')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyWidget();
          }

          final docs = snapshot.data!.docs;
          return _buildPlayersList(docs, isAdmin);
        },
      ),
      floatingActionButton: isAdmin ? _buildFAB(context) : null,
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
            onPressed: () {
              // Sayfa yenileme mantığı
            },
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Henüz oyuncu eklenmemiş'),
          Text('Yeni oyuncu eklemek için + butonuna basın'),
        ],
      ),
    );
  }

  Widget _buildPlayersList(List<QueryDocumentSnapshot> docs, bool isAdmin) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final oyuncu = doc.data() as Map<String, dynamic>;
        return PlayerCard(
          oyuncu: oyuncu,
          oyuncuId: doc.id,
          isAdmin: isAdmin,
        );
      },
    );
  }

  Widget _buildFAB(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: AppColors.primary,
      child: const Icon(Icons.add, color: AppColors.white),
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => const OyuncuEkleDialog(),
        );
      },
    );
  }
}

class PlayerCard extends StatelessWidget {
  final Map<String, dynamic> oyuncu;
  final String oyuncuId;
  final bool isAdmin;

  const PlayerCard({
    super.key,
    required this.oyuncu,
    required this.oyuncuId,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector( // ✅ TIKLANMA ÖZELLİĞİ EKLENDİ
        onTap: () {
          // Foto detay sayfasına git
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FotoDetaySayfasi(
                fotoUrl: oyuncu['fotoUrl'] ?? 'https://via.placeholder.com/300',
                oyuncuAdi: oyuncu['isim'] ?? 'Bilinmeyen',
                pozisyon: oyuncu['pozisyon'] ?? 'Pozisyon Yok',
                formaNo: oyuncu['formaNo'] ?? 0,
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildPlayerAvatar(),
              _buildPlayerInfo(),
              if (isAdmin) _buildAdminMenu(context),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerAvatar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Hero( // ✅ HERO ANİMASYONU EKLENDİ
            tag: 'oyuncu_foto_${oyuncu['formaNo'] ?? 0}',
            child: CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(
                oyuncu['fotoUrl'] ?? 'https://via.placeholder.com/150',
              ),
              onBackgroundImageError: (exception, stackTrace) {
                // Hata durumunda placeholder göster
              },
            ),
          ),
        ),
        // Forma numarası
        Positioned(
          top: 0,
          right: -4,
          child: CircleAvatar(
            radius: 10,
            backgroundColor: Colors.black,
            child: Text(
              '${oyuncu['formaNo'] ?? ''}',
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ),
        // Bayrak
        Positioned(
          top: -4,
          left: -4,
          child: SizedBox(
            width: 24,
            height: 16,
            child: Image.network(
              oyuncu['bayrakUrl'] ?? 'https://flagcdn.com/w20/tr.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey,
                  child: const Icon(Icons.flag, size: 12),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerInfo() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              oyuncu['isim'] ?? 'Bilinmeyen',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              oyuncu['pozisyon'] ?? 'Mevki Yok',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.whiteTransparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppColors.white),
      onSelected: (value) => _handleMenuSelection(context, value),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              const SizedBox(width: 8),
              Text('Düzenle'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, size: 20, color: Colors.red),
              const SizedBox(width: 8),
              Text('Sil', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'edit':
        showDialog(
          context: context,
          builder: (_) => OyuncuDuzenleDialog(
            oyuncuId: oyuncuId,
            oyuncu: oyuncu,
          ),
        );
        break;
      case 'delete':
        _showDeleteConfirmation(context);
        break;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Oyuncuyu Sil"),
          content: Text(
            "'${oyuncu['isim'] ?? 'Bu oyuncu'}' adlı oyuncuyu silmek istediğinizden emin misiniz?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("İptal"),
            ),
            TextButton(
              onPressed: () => _deletePlayer(context),
              child: const Text("Sil", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePlayer(BuildContext context) async {
    try {
      Navigator.of(context).pop(); // Dialog'u kapat

      await FirebaseFirestore.instance
          .collection('Takım')
          .doc(oyuncuId)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Oyuncu silindi!")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Silme hatası: $e")),
        );
      }
    }
  }
}

// Oyuncu Ekleme Dialog'u
class OyuncuEkleDialog extends StatefulWidget {
  const OyuncuEkleDialog({super.key});

  @override
  State<OyuncuEkleDialog> createState() => _OyuncuEkleDialogState();
}

class _OyuncuEkleDialogState extends State<OyuncuEkleDialog> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addPlayers() async {
    if (_controller.text.trim().isEmpty) {
      _showSnackBar("Lütfen JSON verisi girin");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = _controller.text.trim();
      final List<Map<String, dynamic>> players =
      List<Map<String, dynamic>>.from(jsonDecode(data));

      if (players.isEmpty) {
        _showSnackBar("Geçerli oyuncu verisi bulunamadı");
        return;
      }

      final batch = FirebaseFirestore.instance.batch();

      for (var player in players) {
        // Veri doğrulama
        if (!_validatePlayerData(player)) {
          _showSnackBar("Geçersiz oyuncu verisi: ${player['isim'] ?? 'Bilinmeyen'}");
          return;
        }

        final docRef = FirebaseFirestore.instance.collection('Takım').doc();
        batch.set(docRef, player);
      }

      await batch.commit();

      if (mounted) {
        Navigator.of(context).pop();
        _showSnackBar("${players.length} oyuncu başarıyla eklendi!");
      }
    } catch (e) {
      _showSnackBar("Hata: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _validatePlayerData(Map<String, dynamic> player) {
    return player.containsKey('isim') &&
        player.containsKey('formaNo') &&
        player['isim'] != null &&
        player['formaNo'] != null;
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Oyuncu Ekle"),
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
            const SizedBox(height: 16),
            const Text(
              'Not: JSON formatında oyuncu bilgilerini girin',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("İptal"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _addPlayers,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
          ),
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text("Ekle"),
        ),
      ],
    );
  }
}

// Oyuncu Düzenleme Dialog'u
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
  late final TextEditingController _isimController;
  late final TextEditingController _formaNoController;
  late final TextEditingController _pozisyonController;
  late final TextEditingController _fotoUrlController;
  late final TextEditingController _bayrakUrlController;

  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _isimController = TextEditingController(text: widget.oyuncu['isim'] ?? '');
    _formaNoController = TextEditingController(text: "${widget.oyuncu['formaNo'] ?? ''}");
    _pozisyonController = TextEditingController(text: widget.oyuncu['pozisyon'] ?? '');
    _fotoUrlController = TextEditingController(text: widget.oyuncu['fotoUrl'] ?? '');
    _bayrakUrlController = TextEditingController(text: widget.oyuncu['bayrakUrl'] ?? '');
  }

  @override
  void dispose() {
    _isimController.dispose();
    _formaNoController.dispose();
    _pozisyonController.dispose();
    _fotoUrlController.dispose();
    _bayrakUrlController.dispose();
    super.dispose();
  }

  Future<void> _updatePlayer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final formaNo = int.tryParse(_formaNoController.text.trim());
      if (formaNo == null) {
        _showSnackBar("Geçerli bir forma numarası girin");
        return;
      }

      await FirebaseFirestore.instance
          .collection('Takım')
          .doc(widget.oyuncuId)
          .update({
        'isim': _isimController.text.trim(),
        'formaNo': formaNo,
        'pozisyon': _pozisyonController.text.trim(),
        'fotoUrl': _fotoUrlController.text.trim(),
        'bayrakUrl': _bayrakUrlController.text.trim(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        _showSnackBar("Oyuncu başarıyla güncellendi ✅");
      }
    } catch (e) {
      _showSnackBar("Güncelleme hatası: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Oyuncu Düzenle"),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _isimController,
                decoration: const InputDecoration(
                  labelText: "İsim",
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'İsim gerekli';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _formaNoController,
                decoration: const InputDecoration(
                  labelText: "Forma No",
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Forma numarası gerekli';
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return 'Geçerli bir sayı girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _pozisyonController,
                decoration: const InputDecoration(
                  labelText: "Pozisyon",
                  prefixIcon: Icon(Icons.sports_soccer),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fotoUrlController,
                decoration: const InputDecoration(
                  labelText: "Fotoğraf URL",
                  prefixIcon: Icon(Icons.image),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bayrakUrlController,
                decoration: const InputDecoration(
                  labelText: "Bayrak URL",
                  prefixIcon: Icon(Icons.flag),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("İptal"),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updatePlayer,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
          ),
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text("Güncelle"),
        ),
      ],
    );
  }
}