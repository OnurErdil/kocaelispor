// lib/screens/forum_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';
import '../utils/notification_helper.dart';  // ✅ Yeni helper

class ForumSayfasi extends StatefulWidget {
  const ForumSayfasi({super.key});

  @override
  State<ForumSayfasi> createState() => _ForumSayfasiState();
}

class _ForumSayfasiState extends State<ForumSayfasi> {
  final TextEditingController _mesajController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _lastMessageId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeLastMessage();
  }

  @override
  void dispose() {
    _mesajController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // İlk mesaj ID'sini al
  Future<void> _initializeLastMessage() async {
    try {
      final lastMessageDoc = await FirebaseFirestore.instance
          .collection('forum_mesajlari')
          .orderBy('tarih', descending: true)
          .limit(1)
          .get();

      if (lastMessageDoc.docs.isNotEmpty) {
        _lastMessageId = lastMessageDoc.docs.first.id;
      }
    } catch (e) {
      print('Son mesaj ID alınamadı: $e');
    }
  }

  // Mesaj gönderme fonksiyonu
  Future<void> _mesajGonder() async {
    // Boş mesaj kontrolü
    if (_mesajController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Mesaj göndermek için giriş yapmalısınız!', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Firestore'a mesaj kaydet
      await FirebaseFirestore.instance.collection('forum_mesajlari').add({
        'mesaj': _mesajController.text.trim(),
        'gonderenId': user.uid,
        'gonderenAd': user.displayName ?? 'Kocaelispor Taraftarı',
        'gonderenEmail': user.email ?? '',
        'gonderenFoto': user.photoURL,
        'tarih': FieldValue.serverTimestamp(),
        'duzenlendiMi': false,
      });

      // Mesaj kutusunu temizle
      _mesajController.clear();

      // Başarı bildirimi göster
      _showSnackBar('Mesajınız gönderildi! ⚽', isError: false);

      // En alta kaydır
      _scrollToBottom();

    } catch (e) {
      print('Mesaj gönderme hatası: $e');
      _showSnackBar('Mesaj gönderilemedi!', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // SnackBar gösterme
  void _showSnackBar(String message, {required bool isError}) {
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

  // En alta kaydırma
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  // Saat formatı
  String _saatFormatla(DateTime tarih) {
    final now = DateTime.now();
    final difference = now.difference(tarih);

    if (difference.inDays > 0) {
      return DateFormat('dd/MM HH:mm').format(tarih);
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dk önce';
    } else {
      return 'Şimdi';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Taraftar Forumu",
      ),
      body: Column(
        children: [
          // Mesajları gösteren alan
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('forum_mesajlari')
                  .orderBy('tarih', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                // Yükleniyor durumu
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                        ),
                        SizedBox(height: 16),
                        Text('Mesajlar yükleniyor...'),
                      ],
                    ),
                  );
                }

                // Hata durumu
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Hata: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  );
                }

                // Mesaj yoksa
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.forum,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Henüz mesaj yok',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'İlk mesajı sen yaz! ⚽',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final mesajlar = snapshot.data!.docs;

                // Yeni mesaj kontrolü (bildirim için)
                if (mesajlar.isNotEmpty) {
                  final latestMessage = mesajlar.last;
                  final latestMessageId = latestMessage.id;
                  final latestMessageData = latestMessage.data() as Map<String, dynamic>;
                  final currentUser = FirebaseAuth.instance.currentUser;

                  // Eğer yeni mesaj varsa ve başkasının mesajıysa bildirim göster
                  if (_lastMessageId != null &&
                      _lastMessageId != latestMessageId &&
                      latestMessageData['gonderenId'] != currentUser?.uid) {

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      NotificationHelper.showForumMessageNotification(
                        context,
                        senderName: latestMessageData['gonderenAd'] ?? 'Birisi',
                        message: latestMessageData['mesaj'] ?? '',
                      );
                    });
                  }
                  _lastMessageId = latestMessageId;
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: mesajlar.length,
                  itemBuilder: (context, index) {
                    final mesajData = mesajlar[index].data() as Map<String, dynamic>;
                    final currentUser = FirebaseAuth.instance.currentUser;
                    final benimMesajim = mesajData['gonderenId'] == currentUser?.uid;

                    return _mesajBalonuOlustur(mesajData, benimMesajim);
                  },
                );
              },
            ),
          ),

          // Mesaj yazma alanı
          Container(
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
                  // Mesaj yazma kutusu
                  Expanded(
                    child: TextField(
                      controller: _mesajController,
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
                        suffixIcon: _isLoading
                            ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                            ),
                          ),
                        )
                            : null,
                      ),
                      maxLines: null,
                      maxLength: 500, // Karakter limiti
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _mesajGonder(),
                      enabled: !_isLoading,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Gönder butonu
                  FloatingActionButton(
                    onPressed: _isLoading ? null : _mesajGonder,
                    backgroundColor: _isLoading
                        ? Colors.grey
                        : AppTheme.primaryGreen,
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
                        : const Icon(
                      Icons.send,
                      color: Colors.white,
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

  // Mesaj balonu oluşturan fonksiyon
  Widget _mesajBalonuOlustur(Map<String, dynamic> mesajData, bool benimMesajim) {
    final tarih = mesajData['tarih'] as Timestamp?;
    final saatMetni = tarih != null
        ? _saatFormatla(tarih.toDate())
        : 'Şimdi';

    return Align(
      alignment: benimMesajim ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: benimMesajim
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            // Kullanıcı adı (sadece başkalarının mesajları için)
            if (!benimMesajim)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Profil resmi veya avatar
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: AppTheme.primaryGreen,
                      backgroundImage: mesajData['gonderenFoto'] != null
                          ? NetworkImage(mesajData['gonderenFoto'])
                          : null,
                      child: mesajData['gonderenFoto'] == null
                          ? Text(
                        (mesajData['gonderenAd'] ?? '?')[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      mesajData['gonderenAd'] ?? 'Anonim',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // Mesaj balonu
            Container(
              padding: const EdgeInsets.all(12),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              decoration: BoxDecoration(
                color: benimMesajim
                    ? AppTheme.primaryGreen
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: benimMesajim
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: benimMesajim
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mesaj metni
                  Text(
                    mesajData['mesaj'] ?? '',
                    style: TextStyle(
                      color: benimMesajim ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Tarih ve saat
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        saatMetni,
                        style: TextStyle(
                          color: benimMesajim
                              ? Colors.white70
                              : Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                      if (benimMesajim) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}