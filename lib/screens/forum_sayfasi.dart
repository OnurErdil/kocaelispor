// lib/screens/forum_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_app_bar.dart';
import '../services/notification_service.dart'; // ✅ YENİ EKLEME

class ForumSayfasi extends StatefulWidget {
  const ForumSayfasi({super.key});

  @override
  State<ForumSayfasi> createState() => _ForumSayfasiState();
}

class _ForumSayfasiState extends State<ForumSayfasi> {
  final TextEditingController _mesajController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _lastMessageId; // ✅ Son mesaj ID'sini takip etmek için

  @override
  void initState() {
    super.initState();
    _initializeLastMessage(); // ✅ İlk mesaj ID'sini al
  }

  // ✅ İlk mesaj ID'sini al
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mesaj göndermek için giriş yapmalısınız!')),
      );
      return;
    }

    try {
      // Firestore'a mesaj kaydet
      await FirebaseFirestore.instance.collection('forum_mesajlari').add({
        'mesaj': _mesajController.text.trim(),
        'gonderenId': user.uid,
        'gonderenAd': user.displayName ?? 'Kocaelispor Taraftarı',
        'gonderenEmail': user.email ?? '',
        'tarih': FieldValue.serverTimestamp(),
      });

      // Mesaj kutusunu temizle
      _mesajController.clear();

      // Başarı bildirimi göster
      NotificationService.showSuccessNotification(
        context,
        message: 'Mesajınız gönderildi!',
      );

      // En alta kaydır
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      // Hata bildirimi göster
      NotificationService.showErrorNotification(
        context,
        message: 'Mesaj gönderilemedi!',
      );
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
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00913C)),
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
                          'İlk mesajı sen yaz!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final mesajlar = snapshot.data!.docs;

                // ✅ Yeni mesaj kontrolü
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
                      NotificationService.showForumMessageNotification(
                        context,
                        senderName: latestMessageData['gonderenAd'] ?? 'Anonim',
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
                            color: Color(0xFF00913C),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _mesajGonder(),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Gönder butonu
                  FloatingActionButton(
                    onPressed: _mesajGonder,
                    backgroundColor: const Color(0xFF00913C),
                    mini: true,
                    child: const Icon(
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
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: benimMesajim
              ? const Color(0xFF00913C)
              : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: benimMesajim ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: benimMesajim ? const Radius.circular(4) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gönderen adı (eğer başkasının mesajıysa)
            if (!benimMesajim)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  mesajData['gonderenAd'] ?? 'Anonim Taraftar',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),

            // Mesaj metni
            Text(
              mesajData['mesaj'] ?? '',
              style: TextStyle(
                fontSize: 16,
                color: benimMesajim ? Colors.white : Colors.black87,
              ),
            ),

            const SizedBox(height: 4),

            // Saat
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                saatMetni,
                style: TextStyle(
                  fontSize: 11,
                  color: benimMesajim
                      ? Colors.white70
                      : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Saat formatını düzenleyen fonksiyon
  String _saatFormatla(DateTime tarih) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(tarih.year, tarih.month, tarih.day);

    if (messageDate == today) {
      // Bugün ise sadece saat
      return '${tarih.hour.toString().padLeft(2, '0')}:${tarih.minute.toString().padLeft(2, '0')}';
    } else {
      // Başka gün ise tarih ve saat
      return '${tarih.day}/${tarih.month} ${tarih.hour.toString().padLeft(2, '0')}:${tarih.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _mesajController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}