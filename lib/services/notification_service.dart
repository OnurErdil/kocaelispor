// lib/services/notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';  // ✅ Color sınıfı için gerekli
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // ✅ Eksik olan initialize metodu
  static Future<void> initialize() async {
    try {
      print("🔔 Notification Service başlatılıyor...");

      // Local notifications ayarları
      await _initializeLocalNotifications();

      // Firebase messaging ayarları
      await _initializeFirebaseMessaging();

      // Izinleri kontrol et
      await _requestPermissions();

      print("✅ Notification Service başarıyla başlatıldı!");
    } catch (e) {
      print("❌ Notification Service başlatılamadı: $e");
      rethrow;
    }
  }

  // Local notifications başlatma
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    print("📱 Local notifications başlatıldı");
  }

  // Firebase messaging başlatma
  static Future<void> _initializeFirebaseMessaging() async {
    // FCM token al
    final token = await _firebaseMessaging.getToken();
    print("🔑 FCM Token: $token");

    // Foreground mesajlarını dinle
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Background mesajlarını dinle
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // App kapalıyken gelen mesajları kontrol et
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }

    print("🔥 Firebase messaging başlatıldı");
  }

  // İzin isteme
  static Future<void> _requestPermissions() async {
    // iOS için bildirim izni
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Android için bildirim izni (API 33+)
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      print("📢 Android notification permission: $status");
    }

    print("✅ Bildirim izinleri kontrol edildi");
  }

  // Notification tıklandığında
  static void _onNotificationTapped(NotificationResponse response) {
    print("🔔 Notification tıklandı: ${response.payload}");
    // Burada navigation işlemi yapabilirsiniz
  }

  // Foreground mesaj işleme
  static void _handleForegroundMessage(RemoteMessage message) {
    print("📨 Foreground mesaj alındı: ${message.notification?.title}");

    // Local notification göster
    showLocalNotification(
      title: message.notification?.title ?? 'Kocaelispor',
      body: message.notification?.body ?? 'Yeni bildirim',
      payload: message.data.toString(),
    );
  }

  // Background mesaj işleme
  static void _handleBackgroundMessage(RemoteMessage message) {
    print("📨 Background mesaj açıldı: ${message.notification?.title}");
    // Burada navigation işlemi yapabilirsiniz
  }

  // Local notification göster
  static Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'kocaelispor_channel',
      'Kocaelispor Bildirimleri',
      channelDescription: 'Kocaelispor uygulaması bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF4CAF50), // Kocaelispor yeşili
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );

    print("🔔 Local notification gösterildi: $title");
  }

  // Maç bildirimi
  static Future<void> showMatchNotification({
    required String homeTeam,
    required String awayTeam,
    required String matchTime,
  }) async {
    await showLocalNotification(
      title: "⚽ Maç Başlıyor!",
      body: "$homeTeam vs $awayTeam - $matchTime",
      payload: "match_notification",
      id: 1,
    );
  }

  // Haber bildirimi
  static Future<void> showNewsNotification({
    required String title,
    required String content,
  }) async {
    await showLocalNotification(
      title: "📰 Yeni Haber",
      body: title,
      payload: "news_notification",
      id: 2,
    );
  }

  // Gol bildirimi
  static Future<void> showGoalNotification({
    required String playerName,
    required String minute,
  }) async {
    await showLocalNotification(
      title: "⚽ GOL!",
      body: "$playerName ($minute')",
      payload: "goal_notification",
      id: 3,
    );
  }

  // Tüm bildirimleri temizle
  static Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
    print("🧹 Tüm bildirimler temizlendi");
  }

  // Belirli bildirimi iptal et
  static Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
    print("❌ Bildirim iptal edildi: $id");
  }

  // FCM token al
  static Future<String?> getDeviceToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      print("🔑 Device token: $token");
      return token;
    } catch (e) {
      print("❌ Token alınamadı: $e");
      return null;
    }
  }

  // Token yenilendiğinde
  static void listenToTokenRefresh(Function(String) onTokenRefresh) {
    _firebaseMessaging.onTokenRefresh.listen(onTokenRefresh);
  }

  // Bildirim ayarları kontrol et
  static Future<bool> areNotificationsEnabled() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  // Test bildirimi gönder
  static Future<void> sendTestNotification() async {
    await showLocalNotification(
      title: "🧪 Test Bildirimi",
      body: "Bildirimler düzgün çalışıyor!",
      payload: "test_notification",
      id: 999,
    );
  }

  // ✅ Forum için basit bildirim metodları (SnackBar için)
  static void showSuccessNotification(
      BuildContext context, {
        required String message,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static void showErrorNotification(
      BuildContext context, {
        required String message,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showForumMessageNotification(
      BuildContext context, {
        required String senderName,
        required String message,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.forum, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Yeni Forum Mesajı',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '$senderName: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// Background message handler (global fonksiyon olmalı)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("📨 Background mesaj alındı: ${message.notification?.title}");
  // Firebase başlatılmamışsa başlat
  // await Firebase.initializeApp();
}