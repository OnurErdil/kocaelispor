// lib/services/fcm_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'analytics_service.dart';

// Uygulama tamamen kapalıyken gelen mesajları işlemek için
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("📱 Arka planda mesaj geldi:");
  print("Başlık: ${message.notification?.title}");
  print("İçerik: ${message.notification?.body}");
}

// FCM (Firebase Cloud Messaging) servisi
class FCMService {
  // Firebase Messaging örneği
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Local notification'lar için
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // Token'ı saklayacağımız değişken
  static String? _token;

  // Bildirim ayarları
  static bool _newsNotifications = true;
  static bool _matchNotifications = true;
  static bool _generalNotifications = true;

  // Servisi başlatma
  static Future<void> initialize() async {
    print("🔥 FCM Servisi başlatılıyor...");

    // Background handler'ı ayarla
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // İzin isteme
    await _requestPermission();

    // Local notification'ları ayarlama
    await _setupLocalNotifications();

    // FCM token'ını alma
    await _getToken();

    // Mesaj dinleyicilerini ayarlama
    _setupMessageHandlers();

    // Bildirim ayarlarını yükle
    await _loadNotificationSettings();

    print("✅ FCM Servisi başarıyla başlatıldı!");
  }

  // Kullanıcıdan bildirim izni isteme
  static Future<void> _requestPermission() async {
    print("📱 Bildirim izni isteniyor...");

    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
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

  // Local notification'ları ayarlama
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
        _handleNotificationTap(response.payload);
      },
    );

    // Android notification channel oluştur
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'kocaelispor_channel',
      'Kocaelispor Bildirimleri',
      description: 'Kocaelispor uygulaması bildirimleri',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    print("✅ Local notification'lar ayarlandı");
  }

  // FCM token'ını alma
  static Future<void> _getToken() async {
    try {
      _token = await _firebaseMessaging.getToken();
      print("🔑 FCM Token alındı: $_token");

      // Token'ı SharedPreferences'a kaydet
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fcm_token', _token ?? '');

      // Token değişirse bu çalışır
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        print("🔄 FCM Token yenilendi: $newToken");
        _token = newToken;
        _saveTokenToPrefs(newToken);
      });
    } catch (e) {
      print("❌ FCM Token alınamadı: $e");
    }
  }

  // Token'ı SharedPreferences'a kaydet
  static Future<void> _saveTokenToPrefs(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', token);
  }

  // Mesaj dinleyicilerini ayarlama
  static void _setupMessageHandlers() {
    print("👂 Mesaj dinleyicileri ayarlanıyor...");

    // Uygulama açıkken gelen mesajlar
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📨 Uygulama açıkken mesaj geldi:");
      print("Başlık: ${message.notification?.title}");
      print("İçerik: ${message.notification?.body}");

      // Analytics kaydı - mevcut metod ile
      await _analytics.logEvent(
        name: 'notification_received',
        parameters: {
          'type': message.data['type'] ?? 'general',
          'title': message.notification?.title ?? '',
        },
      );

      // Bildirim ayarlarına göre göster
      if (_shouldShowNotification(message)) {
        _showLocalNotification(message);
      }
    });

    // Uygulama kapalıyken tıklanan mesajlar
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🚀 Kapalı uygulamadan mesaj açıldı:");
      print("Başlık: ${message.notification?.title}");

      // Analytics kaydı - mevcut metod ile
      await _analytics.logEvent(
        name: 'notification_opened',
        parameters: {
          'type': message.data['type'] ?? 'general',
          'source': 'background',
        },
      );

      _handleNotificationTap(message.data.toString());
    });

    // Uygulama tamamen kapalıyken açılan mesajları kontrol et
    _checkInitialMessage();

    print("✅ Mesaj dinleyicileri ayarlandı");
  }

  // Uygulama tamamen kapalıyken açılan mesajları kontrol et
  static Future<void> _checkInitialMessage() async {
    RemoteMessage? initialMessage =
    await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      print("🎯 Uygulama kapalıyken mesaja tıklandı");

      // Analytics kaydı - mevcut metod ile
      await _analytics.logEvent(
        name: 'notification_opened',
        parameters: {
          'type': initialMessage.data['type'] ?? 'general',
          'source': 'terminated',
        },
      );

      _handleNotificationTap(initialMessage.data.toString());
    }
  }

  // Bildirim gösterilmeli mi kontrol et
  static bool _shouldShowNotification(RemoteMessage message) {
    final notificationType = message.data['type'] ?? 'general';

    switch (notificationType) {
      case 'news':
        return _newsNotifications;
      case 'match':
        return _matchNotifications;
      case 'general':
        return _generalNotifications;
      default:
        return true;
    }
  }

  // Local notification gösterme
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'kocaelispor_channel',
      'Kocaelispor Bildirimleri',
      channelDescription: 'Kocaelispor uygulaması bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF00913C), // Kocaelispor yeşili
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
      DateTime.now().millisecond,
      message.notification?.title ?? 'Kocaelispor',
      message.notification?.body ?? 'Yeni bildirim',
      details,
      payload: message.data.toString(),
    );
  }

  // Notification'a tıklandığında çalışacak fonksiyon
  static void _handleNotificationTap(String? payload) {
    if (payload == null) return;

    print("🎯 Notification'a tıklandı: $payload");

    // Burada navigation logic'i ekleyebilirsiniz
    // Navigator.pushNamed(context, '/specific-page');
  }

  // Bildirim ayarlarını yükle
  static Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _newsNotifications = prefs.getBool('news_notifications') ?? true;
    _matchNotifications = prefs.getBool('match_notifications') ?? true;
    _generalNotifications = prefs.getBool('general_notifications') ?? true;
  }

  // Bildirim ayarlarını kaydet
  static Future<void> updateNotificationSettings({
    bool? news,
    bool? match,
    bool? general,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (news != null) {
      _newsNotifications = news;
      await prefs.setBool('news_notifications', news);
    }

    if (match != null) {
      _matchNotifications = match;
      await prefs.setBool('match_notifications', match);
    }

    if (general != null) {
      _generalNotifications = general;
      await prefs.setBool('general_notifications', general);
    }

    // Analytics kaydı - mevcut metod ile
    await _analytics.logEvent(
      name: 'notification_settings_changed',
      parameters: {
        'news_enabled': _newsNotifications,
        'match_enabled': _matchNotifications,
        'general_enabled': _generalNotifications,
      },
    );

    print("💾 Bildirim ayarları güncellendi");
  }

  // Topic'e abone ol
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print("📢 Topic'e abone olundu: $topic");
    } catch (e) {
      print("❌ Topic'e abone olunamadı: $e");
    }
  }

  // Topic aboneliğinden çık
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print("🚫 Topic aboneliğinden çıkıldı: $topic");
    } catch (e) {
      print("❌ Topic aboneliğinden çıkılamadı: $e");
    }
  }

  // Getter'lar
  static String? get token => _token;
  static bool get newsNotifications => _newsNotifications;
  static bool get matchNotifications => _matchNotifications;
  static bool get generalNotifications => _generalNotifications;

  // Test bildirimi gönderme
  static Future<void> sendTestNotification() async {
    if (_token == null) {
      print("❌ Token yok, test bildirimi gönderilemez");
      return;
    }

    print("🧪 Test bildirimi için token:");
    print(_token);
    print("Bu token'ı Firebase Console'da test için kullanabilirsiniz");
  }

  // Tüm bildirimleri temizle
  static Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
    print("🧹 Tüm bildirimler temizlendi");
  }

  // Belirli ID'li bildirimi temizle
  static Future<void> clearNotification(int id) async {
    await _localNotifications.cancel(id);
    print("🗑️ Bildirim temizlendi: $id");
  }
}