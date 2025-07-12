// lib/services/fcm_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Bu servis, push notification'ları yönetir
class FCMService {
  // Firebase Messaging örneği
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Local notification'lar için
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // Token'ı saklayacağımız değişken
  static String? _token;

  // Servisi başlatma
  static Future<void> initialize() async {
    print("🔥 FCM Servisi başlatılıyor...");

    // İzin isteme
    await _requestPermission();

    // Local notification'ları ayarlama
    await _setupLocalNotifications();

    // FCM token'ını alma
    await _getToken();

    // Mesaj dinleyicilerini ayarlama
    _setupMessageHandlers();

    print("✅ FCM Servisi başarıyla başlatıldı!");
  }

  // Kullanıcıdan bildirim izni isteme
  static Future<void> _requestPermission() async {
    print("📱 Bildirim izni isteniyor...");

    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,      // Uyarı gösterme
      badge: true,      // Uygulama ikonunda sayı gösterme
      sound: true,      // Ses çalma
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("✅ Kullanıcı bildirim iznini verdi");
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print("⚠️ Kullanıcı geçici bildirim iznini verdi");
    } else {
      print("❌ Kullanıcı bildirim iznini reddetti");
    }
  }

  // Local notification'ları ayarlama (uygulama açıkken göstermek için)
  static Future<void> _setupLocalNotifications() async {
    print("🔔 Local notification'lar ayarlanıyor...");

    // Android ayarları
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS ayarları
    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    // Genel ayarlar
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Local notification'ları başlatma
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("🔔 Local notification'a tıklandı: ${response.payload}");
      },
    );

    print("✅ Local notification'lar ayarlandı");
  }

  // FCM token'ını alma (her cihazın kendine özel kodu)
  static Future<void> _getToken() async {
    try {
      _token = await _firebaseMessaging.getToken();
      print("🔑 FCM Token alındı: $_token");

      // Token değişirse bu çalışır
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print("🔄 FCM Token yenilendi: $newToken");
        _token = newToken;
        // Burada token'ı sunucunuza gönderebilirsiniz
      });

    } catch (e) {
      print("❌ FCM Token alınamadı: $e");
    }
  }

  // Mesaj dinleyicilerini ayarlama
  static void _setupMessageHandlers() {
    print("👂 Mesaj dinleyicileri ayarlanıyor...");

    // Uygulama açıkken gelen mesajlar
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📨 Uygulama açıkken mesaj geldi:");
      print("Başlık: ${message.notification?.title}");
      print("İçerik: ${message.notification?.body}");

      // Local notification göster
      _showLocalNotification(message);
    });

    // Uygulama kapalıyken tıklanan mesajlar
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🚀 Kapalı uygulamadan mesaj açıldı:");
      print("Başlık: ${message.notification?.title}");

      // Burada mesaja göre farklı sayfalara yönlendirebilirsiniz
      _handleNotificationTap(message);
    });

    print("✅ Mesaj dinleyicileri ayarlandı");
  }

  // Local notification gösterme (uygulama açıkken)
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'kocaelispor_channel',    // Kanal ID'si
      'Kocaelispor Bildirimleri', // Kanal adı
      channelDescription: 'Kocaelispor uygulaması bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond, // Benzersiz ID
      message.notification?.title ?? 'Kocaelispor',
      message.notification?.body ?? 'Yeni bildirim',
      details,
      payload: message.data.toString(),
    );
  }

  // Notification'a tıklandığında çalışacak fonksiyon
  static void _handleNotificationTap(RemoteMessage message) {
    print("🎯 Notification'a tıklandı, sayfa yönlendirme yapılabilir");

    // Mesajdaki data'ya göre farklı sayfalara yönlendirebilirsiniz
    final String? page = message.data['page'];

    switch (page) {
      case 'kadro':
        print("👥 Kadro sayfasına yönlendirilecek");
        break;
      case 'takvim':
        print("📅 Takvim sayfasına yönlendirilecek");
        break;
      case 'puan':
        print("🏆 Puan durumu sayfasına yönlendirilecek");
        break;
      default:
        print("🏠 Ana sayfaya yönlendirilecek");
    }
  }

  // Token'ı alma (diğer dosyalardan erişim için)
  static String? get token => _token;

  // Test bildirimi gönderme (geliştirme aşamasında test için)
  static Future<void> sendTestNotification() async {
    if (_token == null) {
      print("❌ Token yok, test bildirimi gönderilemez");
      return;
    }

    print("🧪 Test bildirimi token'ı: $_token");
    print("Bu token'ı Firebase Console'da test için kullanabilirsiniz");
  }
}

// Uygulama tamamen kapalıyken gelen mesajları işlemek için
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("📱 Arka planda mesaj geldi:");
  print("Başlık: ${message.notification?.title}");
  print("İçerik: ${message.notification?.body}");
}}