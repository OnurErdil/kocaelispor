// lib/services/analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver observer =
  FirebaseAnalyticsObserver(analytics: _analytics);

  // Servis başlatma
  static Future<void> initialize() async {
    print("📊 Analytics Service başlatılıyor...");

    // Kullanıcı ID'sini ayarla (giriş yapmışsa)
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await setUserId(user.uid);
    }

    // Uygulama açılış eventi
    await logAppOpen();

    print("✅ Analytics Service hazır!");
  }

  // Kullanıcı ID ayarla
  static Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
    print("👤 Analytics User ID ayarlandı: $userId");
  }

  // Kullanıcı özelliklerini ayarla
  static Future<void> setUserProperties({
    String? userType,
    String? preferredLanguage,
    bool? isPremium,
  }) async {
    if (userType != null) {
      await _analytics.setUserProperty(name: 'user_type', value: userType);
    }
    if (preferredLanguage != null) {
      await _analytics.setUserProperty(name: 'preferred_language', value: preferredLanguage);
    }
    if (isPremium != null) {
      await _analytics.setUserProperty(name: 'is_premium', value: isPremium.toString());
    }
  }

  // 📱 TEMEL EVENTLER

  // Uygulama açılışı
  static Future<void> logAppOpen() async {
    await _analytics.logAppOpen();
    print("📱 Event: Uygulama açıldı");
  }

  // Giriş yapma
  static Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
    print("🔐 Event: Giriş yapıldı - $method");
  }

  // Kayıt olma
  static Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
    print("✍️ Event: Kayıt olundu - $method");
  }

  // Çıkış yapma
  static Future<void> logLogout() async {
    await _analytics.logEvent(name: 'logout');
    print("🚪 Event: Çıkış yapıldı");
  }

  // 🏆 KOCAELISPOR ÖZEL EVENTLER

  // Kadro görüntüleme
  static Future<void> logViewTeam() async {
    await _analytics.logEvent(
      name: 'view_team',
      parameters: {
        'content_type': 'team_roster',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
    print("👥 Event: Kadro görüntülendi");
  }

  // Oyuncu detayı görüntüleme
  static Future<void> logViewPlayer(String playerName, int playerNumber) async {
    await _analytics.logEvent(
      name: 'view_player',
      parameters: {
        'player_name': playerName,
        'player_number': playerNumber,
        'content_type': 'player_detail',
      },
    );
    print("👤 Event: Oyuncu görüntülendi - $playerName (#$playerNumber)");
  }

  // Maç takvimi görüntüleme
  static Future<void> logViewFixture() async {
    await _analytics.logEvent(
      name: 'view_fixture',
      parameters: {
        'content_type': 'match_calendar',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
    print("📅 Event: Maç takvimi görüntülendi");
  }

  // Puan durumu görüntüleme
  static Future<void> logViewLeagueTable() async {
    await _analytics.logEvent(
      name: 'view_league_table',
      parameters: {
        'content_type': 'standings',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
    print("📊 Event: Puan durumu görüntülendi");
  }

  // Profil görüntüleme
  static Future<void> logViewProfile() async {
    await _analytics.logEvent(
      name: 'view_profile',
      parameters: {
        'content_type': 'user_profile',
      },
    );
    print("👤 Event: Profil görüntülendi");
  }

  // 📊 İNTERAKSİYON EVENTLER

  // Oyuncu ekleme (admin)
  static Future<void> logAddPlayer(String playerName) async {
    await _analytics.logEvent(
      name: 'add_player',
      parameters: {
        'player_name': playerName,
        'action_type': 'admin_action',
      },
    );
    print("➕ Event: Oyuncu eklendi - $playerName");
  }

  // Oyuncu düzenleme (admin)
  static Future<void> logEditPlayer(String playerName) async {
    await _analytics.logEvent(
      name: 'edit_player',
      parameters: {
        'player_name': playerName,
        'action_type': 'admin_action',
      },
    );
    print("✏️ Event: Oyuncu düzenlendi - $playerName");
  }

  // Puan durumu güncelleme (admin)
  static Future<void> logUpdateStandings() async {
    await _analytics.logEvent(
      name: 'update_standings',
      parameters: {
        'action_type': 'admin_action',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
    print("🔄 Event: Puan durumu güncellendi");
  }

  // Bildirim ayarları değişikliği
  static Future<void> logNotificationSettings(Map<String, bool> settings) async {
    await _analytics.logEvent(
      name: 'notification_settings_changed',
      parameters: {
        'match_notifications': settings['match'] ?? false,
        'news_notifications': settings['news'] ?? false,
        'general_notifications': settings['general'] ?? false,
      },
    );
    print("🔔 Event: Bildirim ayarları değiştirildi");
  }

  // 🔍 ARAMA VE FİLTRELEME

  // İçerik arama
  static Future<void> logSearch(String searchTerm, String category) async {
    await _analytics.logEvent(
      name: 'search',
      parameters: {
        'search_term': searchTerm,
        'category': category,
      },
    );
    print("🔍 Event: Arama yapıldı - '$searchTerm' ($category)");
  }

  // 🎯 ÖZEL ANALYTICS METODLARI

  // Ekran ziyaret süresi ölçümü başlat
  static DateTime? _screenStartTime;

  static void startScreenTime(String screenName) {
    _screenStartTime = DateTime.now();
    _analytics.logScreenView(screenName: screenName);
    print("⏰ Screen: $screenName başladı");
  }

  // Ekran ziyaret süresi ölçümü bitir
  static Future<void> endScreenTime(String screenName) async {
    if (_screenStartTime != null) {
      final duration = DateTime.now().difference(_screenStartTime!);
      await _analytics.logEvent(
        name: 'screen_view_duration',
        parameters: {
          'screen_name': screenName,
          'duration_seconds': duration.inSeconds,
        },
      );
      print("⏱️ Screen: $screenName - ${duration.inSeconds} saniye");
      _screenStartTime = null;
    }
  }

  // Hata loglama
  static Future<void> logError(String errorType, String errorMessage) async {
    await _analytics.logEvent(
      name: 'app_error',
      parameters: {
        'error_type': errorType,
        'error_message': errorMessage,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
    print("❌ Error: $errorType - $errorMessage");
  }

  // Performance loglama
  static Future<void> logPerformance(String action, int durationMs) async {
    await _analytics.logEvent(
      name: 'performance_metric',
      parameters: {
        'action': action,
        'duration_ms': durationMs,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
    print("⚡ Performance: $action - ${durationMs}ms");
  }

  // 🔓 PUBLIC ACCESSOR (Analytics wrapper için gerekli)

  /// Firebase Analytics instance'ına erişim için public getter
  /// Analytics wrapper ve diğer servislerden erişim için gerekli
  static FirebaseAnalytics get analytics => _analytics;
}