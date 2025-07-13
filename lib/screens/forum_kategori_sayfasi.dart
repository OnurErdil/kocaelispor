import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';
import '../models/forum_models.dart';

class ForumKonuSayfasi extends StatefulWidget {
  final ForumKonu konu;

  const ForumKonuSayfasi({super.key, required this.konu});

  @override
  State<ForumKonuSayfasi> createState() => _ForumKonuSayfasiState();
}

class _ForumKonuSayfasiState extends State<ForumKonuSayfasi> {
  final TextEditingController _mesajController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final List<String> _availableReactions = ['👍', '❤️', '⚽', '🔥', '😍', '👏'];

  // 🔧 GÜVENLİ TİP DÖNÜŞÜM FONKSİYONLARI
  String _safeStringValue(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    return value.toString();
  }

  DateTime _safeDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  bool _safeBoolValue(dynamic value, bool defaultValue) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return defaultValue;
  }

  @override
  void dispose() {
    _mesajController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.konu.baslik,
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 18),
                    SizedBox(width: 8),
                    Text('Yenile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.report, size: 18),
                    SizedBox(width: 8),
                    Text('Şikayet Et'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildKonuBilgi(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // 🔥 INDEX GEREKTİRMEYEN SORGU - sadece konuId ile filtrele
              stream: FirebaseFirestore.instance
                  .collection('forum_mesajlari')
                  .where('konuId', isEqualTo: widget.konu.id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorWidget('Mesajlar yüklenirken hata oluştu: ${snapshot.error}');
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyWidget();
                }

                // 🔥 MANUEL SIRALAMA - tarihe göre sırala (eski mesajlar önce)
                var docs = snapshot.data!.docs.toList();
                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;

                  final aTarih = _safeDateTime(aData['tarih']);
                  final bTarih = _safeDateTime(bData['tarih']);

                  return aTarih.compareTo(bTarih); // Eski mesajlar önce
                });

                // Sayfa açıldığında en alta kaydır
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateToEnd();
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildMesajCard(data, docs[index].id);
                  },
                );
              },
            ),
          ),
          _buildMesajYazmaAlani(),
        ],
      ),
    );
  }

  Widget _buildKonuBilgi() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.konu.baslik,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.konu.aciklama != null && widget.konu.aciklama!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.konu.aciklama!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.person_outline,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                widget.konu.olusturanAd,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.access_time,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                _formatTarih(widget.konu.olusturmaTarihi),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.visibility_outlined,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Text(
                '${widget.konu.goruntulemeSayisi} görüntüleme',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMesajCard(Map<String, dynamic> data, String mesajId) {
    final icerik = _safeStringValue(data['icerik'], '');
    final gonderenAd = _safeStringValue(data['gonderenAd'], 'Anonim');
    final gonderenId = _safeStringValue(data['gonderenId'], '');
    final gonderenFoto = _safeStringValue(data['gonderenFoto'], '');
    final tarih = _safeDateTime(data['tarih']);
    final duzenlendiMi = _safeBoolValue(data['duzenlendiMi'], false);

    final currentUser = FirebaseAuth.instance.currentUser;
    final benimMesajim = gonderenId == currentUser?.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profil fotoğrafı
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primaryGreen,
            backgroundImage: gonderenFoto.isNotEmpty
                ? NetworkImage(gonderenFoto)
                : null,
            child: gonderenFoto.isEmpty
                ? Text(
              gonderenAd.isNotEmpty ? gonderenAd[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
                : null,
          ),

          const SizedBox(width: 12),

          // Mesaj içeriği
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kullanıcı adı ve tarih
                Row(
                  children: [
                    Text(
                      gonderenAd,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: benimMesajim ? AppTheme.primaryGreen : Colors.black87,
                      ),
                    ),
                    if (benimMesajim) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Sen',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      _formatTarih(tarih),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Mesaj içeriği
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: benimMesajim
                        ? AppTheme.primaryGreen.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: benimMesajim
                        ? Border.all(color: AppTheme.primaryGreen.withOpacity(0.3))
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        icerik,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      if (duzenlendiMi) ...[
                        const SizedBox(height: 6),
                        Text(
                          '(düzenlendi)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Reaction butonları
                const SizedBox(height: 8),
                _buildReactionButtons(mesajId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionButtons(String mesajId) {
    return Row(
      children: [
        // Beğeni butonu
        IconButton(
          onPressed: () => _toggleLike(mesajId),
          icon: const Icon(Icons.thumb_up_outlined),
          iconSize: 18,
          color: Colors.grey[600],
        ),

        // Yanıtla butonu
        IconButton(
          onPressed: () => _yanitla(mesajId),
          icon: const Icon(Icons.reply_outlined),
          iconSize: 18,
          color: Colors.grey[600],
        ),

        // Daha fazla
        PopupMenuButton<String>(
          onSelected: (value) => _handleMesajAction(value, mesajId),
          icon: Icon(
            Icons.more_horiz,
            size: 18,
            color: Colors.grey[600],
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'copy',
              child: Row(
                children: [
                  Icon(Icons.copy, size: 16),
                  SizedBox(width: 8),
                  Text('Kopyala'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'report',
              child: Row(
                children: [
                  Icon(Icons.report, size: 16),
                  SizedBox(width: 8),
                  Text('Şikayet Et'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMesajYazmaAlani() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _mesajController,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Mesajınızı yazın...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryGreen,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            FloatingActionButton.small(
              onPressed: _isLoading ? null : _mesajGonder,
              backgroundColor: AppTheme.primaryGreen,
              child: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.send, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.message_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz mesaj yok',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk mesajı sen yaz!',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Future<void> _mesajGonder() async {
    if (_mesajController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Mesaj göndermek için giriş yapmalısınız', true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('forum_mesajlari').add({
        'icerik': _mesajController.text.trim(),
        'konuId': widget.konu.id,
        'gonderenId': user.uid,
        'gonderenAd': user.displayName ?? 'Kocaelispor Taraftarı',
        'gonderenFoto': user.photoURL,
        'tarih': FieldValue.serverTimestamp(),
        'duzenlendiMi': false,
      });

      // Mesaj kutusunu temizle
      _mesajController.clear();

      // Konunun mesaj sayısını artır
      await FirebaseFirestore.instance
          .collection('forum_konulari')
          .doc(widget.konu.id)
          .update({
        'mesajSayisi': FieldValue.increment(1),
        'sonMesajTarihi': FieldValue.serverTimestamp(),
        'sonMesajGonderenAd': user.displayName ?? 'Kocaelispor Taraftarı',
      });

      _showSnackBar('Mesajınız gönderildi! ⚽', false);

      // En alta kaydır
      if (_scrollController.hasClients) {
        _scrollController.animateToEnd();
      }

    } catch (e) {
      print('Mesaj gönderme hatası: $e');
      _showSnackBar('Mesaj gönderilemedi!', true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message, bool isError) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : AppTheme.primaryGreen,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        setState(() {});
        break;
      case 'report':
        _showSnackBar('Şikayet edildi', false);
        break;
    }
  }

  void _handleMesajAction(String action, String mesajId) {
    switch (action) {
      case 'copy':
        _showSnackBar('Mesaj kopyalandı', false);
        break;
      case 'report':
        _showSnackBar('Mesaj şikayet edildi', false);
        break;
    }
  }

  void _toggleLike(String mesajId) {
    _showSnackBar('Beğeni özelliği yakında!', false);
  }

  void _yanitla(String mesajId) {
    _showSnackBar('Yanıtlama özelliği yakında!', false);
  }

  String _formatTarih(DateTime tarih) {
    final now = DateTime.now();
    final difference = now.difference(tarih);

    if (difference.inDays > 7) {
      return DateFormat('dd/MM/yyyy HH:mm').format(tarih);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Şimdi';
    }
  }
}

// ScrollController için extension
extension ScrollControllerExtension on ScrollController {
  void animateToEnd() {
    animateTo(
      position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}