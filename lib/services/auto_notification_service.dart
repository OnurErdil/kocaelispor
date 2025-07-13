// lib/services/auto_notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';

class AutoNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ 1. Yeni haber eklendiğinde bildirim gönder
  static Future<void> setupNewsNotifications() async {
    print("📰 Haber bildirimleri dinleniyor...");

    _firestore
        .collection('haberler')
        .orderBy('tarih', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final title = data['baslik'] ?? 'Yeni Haber';

          // Yeni haber bildirimi gönder
          NotificationService.showNewsNotification(
            title: title,
            content: data['icerik'] ?? '',
          );

          print("📰 Yeni haber bildirimi gönderildi: $title");
        }
      }
    });
  }

  // ✅ 2. Yeni maç eklendiğinde bildirim gönder
  static Future<void> setupMatchNotifications() async {
    print("⚽ Maç bildirimleri dinleniyor...");

    _firestore
        .collection('maclar')
        .where('tarih', isGreaterThan: Timestamp.now())
        .orderBy('tarih')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final evSahibi = data['evSahibi'] ?? 'Takım';
          final deplasman = data['deplasman'] ?? 'Takım';
          final tarih = (data['tarih'] as Timestamp).toDate();

          // Maç tarihi bildirimi
          final matchTime = "${tarih.day}/${tarih.month} ${tarih.hour}:${tarih.minute.toString().padLeft(2, '0')}";

          NotificationService.showMatchNotification(
            homeTeam: evSahibi,
            awayTeam: deplasman,
            matchTime: matchTime,
          );

          print("⚽ Yeni maç bildirimi gönderildi: $evSahibi vs $deplasman");
        }
      }
    });
  }

  // ✅ 3. Maç sonucu güncellendiğinde bildirim gönder
  static Future<void> setupMatchResultNotifications() async {
    print("🏆 Maç sonucu bildirimleri dinleniyor...");

    _firestore
        .collection('maclar')
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data() as Map<String, dynamic>;
          final skor = data['skor'];

          // Eğer skor eklendiyse
          if (skor != null && skor.toString().isNotEmpty) {
            final evSahibi = data['evSahibi'] ?? 'Takım';
            final deplasman = data['deplasman'] ?? 'Takım';

            NotificationService.showLocalNotification(
              title: "🏆 Maç Bitti!",
              body: "$evSahibi $skor $deplasman",
              payload: "match_result",
              id: 100 + DateTime.now().millisecond,
            );

            print("🏆 Maç sonucu bildirimi: $evSahibi $skor $deplasman");
          }
        }
      }
    });
  }

  // ✅ 4. Forum'da yeni mesaj geldiğinde bildirim (opsiyonel)
  static Future<void> setupForumNotifications(String userId) async {
    print("💬 Forum bildirimleri dinleniyor...");

    _firestore
        .collection('forum_mesajlari')
        .where('gonderenId', isNotEqualTo: userId) // Kendi mesajları hariç
        .orderBy('gonderenId') // where kullandığımız için orderBy gerekli
        .orderBy('tarih', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data() as Map<String, dynamic>;
          final gonderenAd = data['gonderenAd'] ?? 'Bilinmeyen';
          final icerik = data['icerik'] ?? '';

          NotificationService.showLocalNotification(
            title: "💬 Yeni Forum Mesajı",
            body: "$gonderenAd: ${icerik.length > 50 ? icerik.substring(0, 50) + '...' : icerik}",
            payload: "forum_message",
            id: 200 + DateTime.now().millisecond,
          );

          print("💬 Forum bildirimi gönderildi: $gonderenAd");
        }
      }
    });
  }

  // ✅ 5. Tüm bildirimleri başlat
  static Future<void> startAllNotifications({String? userId}) async {
    print("🚀 Tüm otomatik bildirimler başlatılıyor...");

    try {
      await setupNewsNotifications();
      await setupMatchNotifications();
      await setupMatchResultNotifications();

      if (userId != null) {
        await setupForumNotifications(userId);
      }

      print("✅ Tüm otomatik bildirimler aktif!");

    } catch (e) {
      print("❌ Otomatik bildirimler başlatılamadı: $e");
    }
  }

  // ✅ 6. Özel bildirimler

  // Maça 1 saat kala uyarı
  static Future<void> scheduleMatchReminder(Map<String, dynamic> macData) async {
    final tarih = (macData['tarih'] as Timestamp).toDate();
    final now = DateTime.now();
    final difference = tarih.difference(now);

    // Eğer maça 1 saatten az kaldıysa
    if (difference.inMinutes <= 60 && difference.inMinutes > 0) {
      final evSahibi = macData['evSahibi'] ?? 'Takım';
      final deplasman = macData['deplasman'] ?? 'Takım';

      await NotificationService.showLocalNotification(
        title: "⏰ Maç Yaklaşıyor!",
        body: "$evSahibi vs $deplasman ${difference.inMinutes} dakika sonra başlayacak",
        payload: "match_reminder",
        id: 300 + DateTime.now().millisecond,
      );

      print("⏰ Maç hatırlatması gönderildi: ${difference.inMinutes} dakika kaldı");
    }
  }

  // Transfer haberi özel bildirimi
  static Future<void> sendTransferNotification(String playerName, String transferType) async {
    String title = "";
    String emoji = "";

    switch (transferType.toLowerCase()) {
      case 'geliş':
      case 'gelen':
        title = "🎉 Hoş Geldin!";
        emoji = "➕";
        break;
      case 'gidiş':
      case 'giden':
        title = "👋 Yolun Açık Olsun";
        emoji = "➖";
        break;
      default:
        title = "🔄 Transfer Haberi";
        emoji = "🔄";
    }

    await NotificationService.showLocalNotification(
      title: title,
      body: "$emoji $playerName - Transfer tamamlandı",
      payload: "transfer_news",
      id: 400 + DateTime.now().millisecond,
    );

    print("🔄 Transfer bildirimi: $playerName ($transferType)");
  }

  // Önemli duyuru bildirimi
  static Future<void> sendImportantAnnouncement(String title, String content) async {
    await NotificationService.showLocalNotification(
      title: "📢 ÖNEMLİ DUYURU",
      body: title,
      payload: "important_announcement",
      id: 500 + DateTime.now().millisecond,
    );

    print("📢 Önemli duyuru bildirimi gönderildi: $title");
  }
}