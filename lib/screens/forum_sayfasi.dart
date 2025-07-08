// lib/screens/forum_sayfasi.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_app_bar.dart';

class ForumSayfasi extends StatefulWidget {
  const ForumSayfasi({super.key});

  @override
  State<ForumSayfasi> createState() => _ForumSayfasiState();
}

class _ForumSayfasiState extends State<ForumSayfasi> {
  final TextEditingController _mesajController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Mesaj gönderme fonksiyonu
  Future<void> _mesajGonder() async {
    // Boş mesaj kontrolü
    if (_mesajController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Firestore'a mesaj kaydet
      await FirebaseFirestore.instance.collection('forum_mesajlari').add({
        'mesaj': _mesajController.text.trim(),
        'gonderenId': user.uid,
        'gonderenAd': user.displayName ?? 'Anonim Taraftar',
        'gonderenEmail': user.email ?? '',
        'tarih': FieldValue.serverTimestamp(),
      });

      // Mesaj kutusunu temizle
      _mesajController.clear();

      // En alta kaydır
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      // Hata mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mesaj gönderilemedi: $e')),
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
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00913C)),
                    ),
                  );
                }

                // Hata durumu
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Hata: ${snapshot.error}'),
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
                        Text(
                          'İlk mesajı sen yaz!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final mesajlar = snapshot.data!.docs;

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
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
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
        ],
      ),
    );
  }

  // Mesaj balonu oluşturan fonksiyon
  Widget _mesajBalonuOlustur(Map<String, dynamic> mesajData, bool benimMesajim) {
    final tarih = mesajData['tarih'] as Timestamp?;
    final saatMetni = tarih != null
        ? _saatFormatla(tarih.toDate())
        : 'Bilinmiyor';

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
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gönderen adı (eğer başkasının mesajıysa)
            if (!benimMesajim)
              Text(
                mesajData['gonderenAd'] ?? 'Anonim',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
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
            Text(
              saatMetni,
              style: TextStyle(
                fontSize: 11,
                color: benimMesajim
                    ? Colors.white70
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Saat formatını düzenleyen fonksiyon
  String _saatFormatla(DateTime tarih) {
    return '${tarih.hour.toString().padLeft(2, '0')}:${tarih.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _mesajController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}