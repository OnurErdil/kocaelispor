// lib/screens/forum_konu_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';
import '../models/forum_models.dart';
import '../services/forum_service.dart';

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

  // Mevcut reactions
  final List<String> _availableReactions = ['👍', '❤️', '⚽', '🔥', '😍', '👏'];

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
          // Konu bilgileri
          _buildKonuBilgi(),

          // Mesajlar listesi
          Expanded(
            child: StreamBuilder<List<ForumMesaj>>(
              stream: ForumService.getMesajlar(widget.konu.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorWidget('Mesajlar yüklenirken hata oluştu');
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyWidget();
                }

                final mesajlar = snapshot.data!;

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: mesajlar.length,
                  itemBuilder: (context, index) {
                    final mesaj = mesajlar[index];
                    return _buildMesajCard(mesaj);
                  },
                );
              },
            ),
          ),

          // Mesaj yazma alanı
          _buildMesajYazmaAlani(),
        ],
      ),
    );
  }

  Widget _buildKonuBilgi() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık ve etiket
          Row(
            children: [
              if (widget.konu.sabitlenmis)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.push_pin,
                    size: 16,
                    color: Colors.orange[600],
                  ),
                ),

              if (widget.konu.kilitli)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.lock,
                    size: 16,
                    color: Colors.red[600],
                  ),
                ),

              Expanded(
                child: Text(
                  widget.konu.baslik,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              if (widget.konu.etiket != null && widget.konu.etiket!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.konu.etiketRengi.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.konu.etiketRengi,
                    ),
                  ),
                  child: Text(
                    widget.konu.etiketMetni,
                    style: TextStyle(
                      fontSize: 10,
                      color: widget.konu.etiketRengi,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          // Açıklama (varsa)
          if (widget.konu.aciklama != null && widget.konu.aciklama!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.konu.aciklama!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Alt bilgiler
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppTheme.primaryGreen,
                backgroundImage: widget.konu.olusturanFoto != null
                    ? NetworkImage(widget.konu.olusturanFoto!)
                    : null,
                child: widget.konu.olusturanFoto == null
                    ? Text(
                  widget.konu.olusturanAd[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.konu.olusturanAd,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatTarih(widget.konu.olusturmaTarihi),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),

              // İstatistikler
              _buildStatChip(
                Icons.message_outlined,
                widget.konu.mesajSayisi.toString(),
                Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                Icons.visibility_outlined,
                widget.konu.goruntulemeSayisi.toString(),
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMesajCard(ForumMesaj mesaj) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final benimMesajim = mesaj.gonderenId == currentUser?.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profil fotoğrafı
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primaryGreen,
            backgroundImage: mesaj.gonderenFoto != null
                ? NetworkImage(mesaj.gonderenFoto!)
                : null,
            child: mesaj.gonderenFoto == null
                ? Text(
              mesaj.gonderenAd[0].toUpperCase(),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
                : null,
          ),

          const SizedBox(width: 12),

          // Mesaj içeriği
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: benimMesajim
                    ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: benimMesajim
                    ? Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.3))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kullanıcı adı ve tarih
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          mesaj.gonderenAd,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: benimMesajim ? AppTheme.primaryGreen : Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        _formatTarih(mesaj.tarih),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (benimMesajim)
                        PopupMenuButton<String>(
                          onSelected: (value) => _handleMesajAction(value, mesaj),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, size: 16),
                                  SizedBox(width: 8),
                                  Text('Düzenle'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, size: 16, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Sil', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                          icon: Icon(
                            Icons.more_vert,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Mesaj içeriği
                  Text(
                    mesaj.icerik,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),

                  // Düzenlenme bilgisi
                  if (mesaj.duzenlendiMi) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Düzenlendi',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Reactions
                  _buildReactions(mesaj),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactions(ForumMesaj mesaj) {
    return Row(
      children: [
        // Mevcut reactions
        ...mesaj.reactionSayilari.entries.map((entry) {
          final reaction = entry.key;
          final count = entry.value;

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => _toggleReaction(mesaj.id, reaction),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(reaction, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      count.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),

        // Reaction ekleme butonu
        InkWell(
          onTap: () => _showReactionPicker(mesaj.id),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.add_reaction_outlined,
              size: 16,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMesajYazmaAlani() {
    if (widget.konu.kilitli) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          border: Border(
            top: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.lock, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text(
              'Bu konu kilitlendi. Yeni mesaj yazamazsınız.',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              onPressed: _isLoading ? null : _mesajGonder,
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              mini: true,
              child: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.message_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Henüz mesaj yok',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'İlk mesajı sen yaz!',
            style: TextStyle(
              color: Colors.grey,
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

  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        setState(() {});
        break;
      case 'report':
        _showReportDialog();
        break;
    }
  }

  void _handleMesajAction(String action, ForumMesaj mesaj) {
    switch (action) {
      case 'edit':
        _showEditMesajDialog(mesaj);
        break;
      case 'delete':
        _showDeleteMesajDialog(mesaj);
        break;
    }
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
      final yeniMesaj = ForumMesaj(
        id: '',
        icerik: _mesajController.text.trim(),
        konuId: widget.konu.id,
        gonderenId: user.uid,
        gonderenAd: user.displayName ?? 'Kocaelispor Taraftarı',
        gonderenFoto: user.photoURL,
        tarih: DateTime.now(),
      );

      final mesajId = await ForumService.mesajEkle(yeniMesaj);

      if (mesajId != null) {
        _mesajController.clear();
        _showSnackBar('Mesajınız gönderildi! ⚽', false);

        // En alta kaydır
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        _showSnackBar('Mesaj gönderilemedi', true);
      }
    } catch (e) {
      print('Mesaj gönderme hatası: $e');
      _showSnackBar('Bir hata oluştu', true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleReaction(String mesajId, String reaction) async {
    await ForumService.mesajReactionGuncelle(mesajId, reaction);
  }

  void _showReactionPicker(String mesajId) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bir reaction seçin:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              children: _availableReactions.map((reaction) {
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _toggleReaction(mesajId, reaction);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      reaction,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMesajDialog(ForumMesaj mesaj) {
    final controller = TextEditingController(text: mesaj.icerik);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mesajı Düzenle'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Mesajınızı düzenleyin...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context);
                final success = await ForumService.mesajGuncelle(
                  mesaj.id,
                  controller.text.trim(),
                );
                if (success) {
                  _showSnackBar('Mesaj güncellendi', false);
                } else {
                  _showSnackBar('Mesaj güncellenemedi', true);
                }
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

  void _showDeleteMesajDialog(ForumMesaj mesaj) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mesajı Sil'),
        content: const Text('Bu mesajı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ForumService.mesajSil(mesaj.id);
              if (success) {
                _showSnackBar('Mesaj silindi', false);
              } else {
                _showSnackBar('Mesaj silinemedi', true);
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

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şikayet Et'),
        content: const Text('Bu konuyu neden şikayet ediyorsunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Şikayetiniz alındı', false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Şikayet Et'),
          ),
        ],
      ),
    );
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