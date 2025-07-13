// lib/services/forum_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/forum_models.dart';

class ForumService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==================== KATEGORİ İŞLEMLERİ ====================

  // Tüm kategorileri getir
  static Stream<List<ForumKategori>> getKategoriler() {
    return _firestore
        .collection('forum_kategorileri')
        .where('aktif', isEqualTo: true)
        .orderBy('sira')
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ForumKategori.fromFirestore(doc))
        .toList());
  }

  // Kategori ekle (Admin)
  static Future<bool> kategoriEkle(ForumKategori kategori) async {
    try {
      await _firestore
          .collection('forum_kategorileri')
          .doc(kategori.id)
          .set(kategori.toMap());
      return true;
    } catch (e) {
      print('Kategori ekleme hatası: $e');
      return false;
    }
  }

  // Kategori güncelle (Admin)
  static Future<bool> kategoriGuncelle(String kategoriId, Map<String, dynamic> veri) async {
    try {
      await _firestore
          .collection('forum_kategorileri')
          .doc(kategoriId)
          .update(veri);
      return true;
    } catch (e) {
      print('Kategori güncelleme hatası: $e');
      return false;
    }
  }

  // Kategori sil (Admin)
  static Future<bool> kategoriSil(String kategoriId) async {
    try {
      // Kategoriye ait tüm konuları da sil
      final konular = await _firestore
          .collection('forum_konulari')
          .where('kategoriId', isEqualTo: kategoriId)
          .get();

      final batch = _firestore.batch();

      // Konuları sil
      for (var doc in konular.docs) {
        batch.delete(doc.reference);

        // Konuya ait mesajları da sil
        final mesajlar = await _firestore
            .collection('forum_mesajlari')
            .where('konuId', isEqualTo: doc.id)
            .get();

        for (var mesajDoc in mesajlar.docs) {
          batch.delete(mesajDoc.reference);
        }
      }

      // Kategoriyi sil
      batch.delete(_firestore.collection('forum_kategorileri').doc(kategoriId));

      await batch.commit();
      return true;
    } catch (e) {
      print('Kategori silme hatası: $e');
      return false;
    }
  }

  // Varsayılan kategorileri oluştur
  static Future<void> varsayilanKategorileriOlustur() async {
    try {
      final kategoriler = VarsayilanKategoriler.getVarsayilanlar();

      for (var kategori in kategoriler) {
        final docRef = _firestore.collection('forum_kategorileri').doc(kategori.id);
        final doc = await docRef.get();

        if (!doc.exists) {
          await docRef.set(kategori.toMap());
        }
      }
    } catch (e) {
      print('Varsayılan kategoriler oluşturma hatası: $e');
    }
  }

  // ==================== KONU İŞLEMLERİ ====================

  // Kategoriye göre konuları getir
  static Stream<List<ForumKonu>> getKonular(String kategoriId) {
    return _firestore
        .collection('forum_konulari')
        .where('kategoriId', isEqualTo: kategoriId)
        .orderBy('sabitlenmis', descending: true)
        .orderBy('sonMesajTarihi', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ForumKonu.fromFirestore(doc))
        .toList());
  }

  // Konu ekle
  static Future<String?> konuEkle(ForumKonu konu) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final docRef = await _firestore
          .collection('forum_konulari')
          .add(konu.toMap());

      // Kategori istatistiklerini güncelle
      await _kategoriIstatistikGuncelle(konu.kategoriId);

      return docRef.id;
    } catch (e) {
      print('Konu ekleme hatası: $e');
      return null;
    }
  }

  // Konu güncelle
  static Future<bool> konuGuncelle(String konuId, Map<String, dynamic> veri) async {
    try {
      await _firestore
          .collection('forum_konulari')
          .doc(konuId)
          .update(veri);
      return true;
    } catch (e) {
      print('Konu güncelleme hatası: $e');
      return false;
    }
  }

  // Konu sil
  static Future<bool> konuSil(String konuId) async {
    try {
      // Önce konuya ait mesajları sil
      final mesajlar = await _firestore
          .collection('forum_mesajlari')
          .where('konuId', isEqualTo: konuId)
          .get();

      final batch = _firestore.batch();

      for (var mesajDoc in mesajlar.docs) {
        batch.delete(mesajDoc.reference);
      }

      // Konuyu sil
      batch.delete(_firestore.collection('forum_konulari').doc(konuId));

      await batch.commit();
      return true;
    } catch (e) {
      print('Konu silme hatası: $e');
      return false;
    }
  }

  // Konu görüntüleme sayısını artır
  static Future<void> konuGoruntulemeSayisiniArtir(String konuId) async {
    try {
      await _firestore
          .collection('forum_konulari')
          .doc(konuId)
          .update({'goruntulemeSayisi': FieldValue.increment(1)});
    } catch (e) {
      print('Görüntüleme sayısı artırma hatası: $e');
    }
  }

  // ==================== MESAJ İŞLEMLERİ ====================

  // Konuya göre mesajları getir
  static Stream<List<ForumMesaj>> getMesajlar(String konuId) {
    return _firestore
        .collection('forum_mesajlari')
        .where('konuId', isEqualTo: konuId)
        .orderBy('tarih', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ForumMesaj.fromFirestore(doc))
        .toList());
  }

  // Mesaj ekle
  static Future<String?> mesajEkle(ForumMesaj mesaj) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final docRef = await _firestore
          .collection('forum_mesajlari')
          .add(mesaj.toMap());

      // Konu istatistiklerini güncelle
      await _konuIstatistikGuncelle(mesaj.konuId, mesaj.gonderenAd);

      return docRef.id;
    } catch (e) {
      print('Mesaj ekleme hatası: $e');
      return null;
    }
  }

  // Mesaj güncelle
  static Future<bool> mesajGuncelle(String mesajId, String yeniIcerik) async {
    try {
      await _firestore
          .collection('forum_mesajlari')
          .doc(mesajId)
          .update({
        'icerik': yeniIcerik,
        'duzenlendiMi': true,
        'duzenlenmeTarihi': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Mesaj güncelleme hatası: $e');
      return false;
    }
  }

  // Mesaj sil
  static Future<bool> mesajSil(String mesajId) async {
    try {
      await _firestore
          .collection('forum_mesajlari')
          .doc(mesajId)
          .delete();
      return true;
    } catch (e) {
      print('Mesaj silme hatası: $e');
      return false;
    }
  }

  // Mesaja reaction ekle/çıkar
  static Future<bool> mesajReactionGuncelle(String mesajId, String reaction) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final mesajRef = _firestore.collection('forum_mesajlari').doc(mesajId);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(mesajRef);
        if (!doc.exists) return;

        final data = doc.data()!;
        final reactionSayilari = Map<String, int>.from(data['reactionSayilari'] ?? {});
        final userReactions = List<String>.from(data['userReactions_${user.uid}'] ?? []);

        if (userReactions.contains(reaction)) {
          // Reaction'ı kaldır
          userReactions.remove(reaction);
          reactionSayilari[reaction] = (reactionSayilari[reaction] ?? 1) - 1;
          if (reactionSayilari[reaction]! <= 0) {
            reactionSayilari.remove(reaction);
          }
        } else {
          // Reaction ekle
          userReactions.add(reaction);
          reactionSayilari[reaction] = (reactionSayilari[reaction] ?? 0) + 1;
        }

        transaction.update(mesajRef, {
          'reactionSayilari': reactionSayilari,
          'userReactions_${user.uid}': userReactions,
        });
      });

      return true;
    } catch (e) {
      print('Reaction güncelleme hatası: $e');
      return false;
    }
  }

  // ==================== YARDIMCI METODLAR ====================

  // Kategori istatistiklerini güncelle
  static Future<void> _kategoriIstatistikGuncelle(String kategoriId) async {
    try {
      final konuSayisi = await _firestore
          .collection('forum_konulari')
          .where('kategoriId', isEqualTo: kategoriId)
          .get()
          .then((snapshot) => snapshot.docs.length);

      final mesajSayisi = await _firestore
          .collection('forum_mesajlari')
          .where('kategoriId', isEqualTo: kategoriId)
          .get()
          .then((snapshot) => snapshot.docs.length);

      await _firestore
          .collection('forum_kategorileri')
          .doc(kategoriId)
          .update({
        'konuSayisi': konuSayisi,
        'mesajSayisi': mesajSayisi,
        'sonAktivite': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Kategori istatistik güncelleme hatası: $e');
    }
  }

  // Konu istatistiklerini güncelle
  static Future<void> _konuIstatistikGuncelle(String konuId, String gonderenAd) async {
    try {
      final mesajSayisi = await _firestore
          .collection('forum_mesajlari')
          .where('konuId', isEqualTo: konuId)
          .get()
          .then((snapshot) => snapshot.docs.length);

      await _firestore
          .collection('forum_konulari')
          .doc(konuId)
          .update({
        'mesajSayisi': mesajSayisi,
        'sonMesajTarihi': FieldValue.serverTimestamp(),
        'sonMesajGonderenAd': gonderenAd,
      });
    } catch (e) {
      print('Konu istatistik güncelleme hatası: $e');
    }
  }

  // ==================== MAÇA ÖZEL KONU OLUŞTURMA ====================

  // Gelecek maç için otomatik konu oluştur
  static Future<void> macKonusuOlustur({
    required String macBasligi, // "1. Hafta: Trabzonspor - Kocaelispor"
    required DateTime macTarihi,
    required String evSahibi,
    required String deplasman,
    required String stadyum,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final konu = ForumKonu(
        id: '', // Firestore otomatik oluşturacak
        baslik: macBasligi,
        aciklama: 'Maç öncesi ve sonrası değerlendirmeler için konu',
        kategoriId: 'maclar',
        olusturanId: 'system',
        olusturanAd: 'Sistem',
        olusturmaTarihi: DateTime.now(),
        etiket: 'important',
      );

      final konuId = await konuEkle(konu);

      if (konuId != null) {
        // İlk sistem mesajını ekle
        final ilkMesaj = ForumMesaj(
          id: '',
          icerik: '''🏟️ **$macBasligi**

📅 **Tarih:** ${_formatTarih(macTarihi)}
🏟️ **Stadyum:** $stadyum
⚽ **Karşılaşma:** $evSahibi vs $deplasman

Maç öncesi ve sonrası düşüncelerinizi paylaşabilirsiniz!

Haydi Kocaelispor! 💚🖤''',
          konuId: konuId,
          gonderenId: 'system',
          gonderenAd: 'Sistem',
          tarih: DateTime.now(),
        );

        await mesajEkle(ilkMesaj);
      }
    } catch (e) {
      print('Maç konusu oluşturma hatası: $e');
    }
  }

  static String _formatTarih(DateTime tarih) {
    final days = ['Pazartesi', 'Salı', 'Çarşamba', 'Perşembe', 'Cuma', 'Cumartesi', 'Pazar'];
    final months = ['Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'];

    return '${tarih.day} ${months[tarih.month - 1]} ${tarih.year}, ${days[tarih.weekday - 1]} ${tarih.hour.toString().padLeft(2, '0')}:${tarih.minute.toString().padLeft(2, '0')}';
  }
}