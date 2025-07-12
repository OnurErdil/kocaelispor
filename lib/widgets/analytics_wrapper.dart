// lib/widgets/analytics_wrapper.dart
import 'package:flutter/material.dart';
import 'package:firebase_analytics/firebase_analytics.dart'; // ✅ Firebase Analytics import eklendi
import '../services/analytics_service.dart';

/// Analytics takibi için widget wrapper
/// Sayfa görüntüleme sürelerini ve ekran geçişlerini otomatik takip eder
class AnalyticsWrapper extends StatefulWidget {
  final Widget child;
  final String screenName;
  final VoidCallback? onScreenView;
  final Map<String, dynamic>? screenParameters;

  const AnalyticsWrapper({
    super.key,
    required this.child,
    required this.screenName,
    this.onScreenView,
    this.screenParameters,
  });

  @override
  State<AnalyticsWrapper> createState() => _AnalyticsWrapperState();
}

class _AnalyticsWrapperState extends State<AnalyticsWrapper>
    with WidgetsBindingObserver {
  bool _isActive = true;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Sayfa yüklendiğinde analytics başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScreenTracking();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Sayfa kapanırken analytics bitir
    _endScreenTracking();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Uygulama arka plana gidince tracking'i durdur
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        if (_isActive) {
          _endScreenTracking();
          _isActive = false;
        }
        break;
      case AppLifecycleState.resumed:
        if (!_isActive) {
          _startScreenTracking();
          _isActive = true;
        }
        break;
      case AppLifecycleState.inactive:
      // Geçici durumlar için bir şey yapmıyoruz
        break;
    }
  }

  void _startScreenTracking() {
    try {
      _startTime = DateTime.now();

      // Screen view eventi gönder (mevcut metodları kullan)
      AnalyticsService.startScreenTime(widget.screenName);

      // Özel callback varsa çalıştır
      widget.onScreenView?.call();

      print("📊 Analytics: ${widget.screenName} tracking başladı");
    } catch (e) {
      print("❌ Analytics tracking başlatılamadı: $e");
    }
  }

  void _endScreenTracking() {
    try {
      if (_startTime != null) {
        final duration = DateTime.now().difference(_startTime!);

        // Screen time eventi gönder (mevcut metodları kullan)
        AnalyticsService.endScreenTime(widget.screenName);

        print("📊 Analytics: ${widget.screenName} - ${duration.inSeconds}s");
        _startTime = null;
      }
    } catch (e) {
      print("❌ Analytics tracking sonlandırılamadı: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Analytics işlemleri için yardımcı metodlar
class AnalyticsHelper {

  /// Sayfa wrapper'ı - kolay kullanım için
  static Widget wrapScreen({
    required Widget child,
    required String screenName,
    VoidCallback? onScreenView,
    Map<String, dynamic>? screenParameters,
  }) {
    return AnalyticsWrapper(
      screenName: screenName,
      onScreenView: onScreenView,
      screenParameters: screenParameters,
      child: child,
    );
  }

  /// Buton tıklama analytics'i
  static VoidCallback wrapButtonPress({
    required VoidCallback onPressed,
    required String buttonName,
    String? category,
    Map<String, dynamic>? parameters,
  }) {
    return () {
      try {
        // Analytics eventi kaydet
        final analytics = AnalyticsService.analytics;
        await analytics.logEvent(
          name: 'button_click',
          parameters: {
            'button_name': buttonName,
            'category': category ?? 'general',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            ...?parameters,
          },
        );

        // Orijinal fonksiyonu çalıştır
        onPressed();
      } catch (e) {
        print("❌ Button analytics kaydedilemedi: $e");
        // Hata olsa bile orijinal fonksiyonu çalıştır
        onPressed();
      }
    };
  }

  /// Form gönderme analytics'i
  static VoidCallback wrapFormSubmit({
    required VoidCallback onSubmit,
    required String formName,
    Map<String, dynamic>? formData,
  }) {
    return () {
      try {
        // Form submit eventi kaydet
        final analytics = AnalyticsService.analytics;
        await analytics.logEvent(
          name: 'form_submit',
          parameters: {
            'form_name': formName,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            ...?formData,
          },
        );

        // Orijinal fonksiyonu çalıştır
        onSubmit();
      } catch (e) {
        print("❌ Form analytics kaydedilemedi: $e");
        // Hata olsa bile orijinal fonksiyonu çalıştır
        onSubmit();
      }
    };
  }

  /// Listview item tıklama analytics'i
  static VoidCallback wrapListItemTap({
    required VoidCallback onTap,
    required String itemType,
    required String itemId,
    int? itemIndex,
    Map<String, dynamic>? itemData,
  }) {
    return () {
      try {
        // List item tap eventi kaydet
        final analytics = AnalyticsService.analytics;
        await analytics.logEvent(
          name: 'list_item_tap',
          parameters: {
            'item_type': itemType,
            'item_id': itemId,
            if (itemIndex != null) 'item_index': itemIndex,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            ...?itemData,
          },
        );

        // Orijinal fonksiyonu çalıştır
        onTap();
      } catch (e) {
        print("❌ List item analytics kaydedilemedi: $e");
        // Hata olsa bile orijinal fonksiyonu çalıştır
        onTap();
      }
    };
  }

  /// Search analytics'i
  static void logSearch({
    required String searchTerm,
    required String category,
    int? resultCount,
    Map<String, dynamic>? filters,
  }) {
    try {
      AnalyticsService.logSearch(searchTerm, category);
    } catch (e) {
      print("❌ Search analytics kaydedilemedi: $e");
    }
  }

  /// Feature kullanımı analytics'i
  static void logFeatureUsage({
    required String featureName,
    String? action,
    Map<String, dynamic>? parameters,
  }) {
    try {
      // Feature usage kaydet
      final analytics = AnalyticsService.analytics;
      await analytics.logEvent(
        name: 'feature_usage',
        parameters: {
          'feature_name': featureName,
          if (action != null) 'action': action,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          ...?parameters,
        },
      );
    } catch (e) {
      print("❌ Feature usage analytics kaydedilemedi: $e");
    }
  }

  /// Error analytics'i
  static void logError({
    required String errorType,
    required String errorMessage,
    String? screenName,
    Map<String, dynamic>? context,
  }) {
    try {
      AnalyticsService.logError(errorType, errorMessage);
    } catch (e) {
      print("❌ Error analytics kaydedilemedi: $e");
    }
  }

  /// Performance analytics'i
  static void logPerformance({
    required String action,
    required int durationMs,
    String? category,
    Map<String, dynamic>? parameters,
  }) {
    try {
      AnalyticsService.logPerformance(action, durationMs);
    } catch (e) {
      print("❌ Performance analytics kaydedilemedi: $e");
    }
  }
}

/// Analytics event tipleri için constants
class AnalyticsEvents {
  // Screen names
  static const String screenHome = 'home_screen';
  static const String screenTeam = 'team_screen';
  static const String screenFixtures = 'fixtures_screen';
  static const String screenProfile = 'profile_screen';
  static const String screenSettings = 'settings_screen';
  static const String screenLogin = 'login_screen';
  static const String screenForum = 'forum_screen';

  // Button categories
  static const String categoryNavigation = 'navigation';
  static const String categoryAction = 'action';
  static const String categorySettings = 'settings';
  static const String categoryAuth = 'auth';
  static const String categorySocial = 'social';

  // Feature names
  static const String featurePlayerSearch = 'player_search';
  static const String featureMatchCalendar = 'match_calendar';
  static const String featureForumMessage = 'forum_message';
  static const String featureNotifications = 'notifications';
  static const String featureThemeChange = 'theme_change';
  static const String featureLanguageChange = 'language_change';
}

/// Analytics için extension metodlar
extension AnalyticsWidgetExtension on Widget {
  /// Widget'ı analytics wrapper ile sarma
  Widget withAnalytics({
    required String screenName,
    VoidCallback? onScreenView,
    Map<String, dynamic>? screenParameters,
  }) {
    return AnalyticsWrapper(
      screenName: screenName,
      onScreenView: onScreenView,
      screenParameters: screenParameters,
      child: this,
    );
  }
}

extension AnalyticsButtonExtension on VoidCallback {
  /// Button callback'ini analytics ile sarma
  VoidCallback withAnalytics({
    required String buttonName,
    String? category,
    Map<String, dynamic>? parameters,
  }) {
    return AnalyticsHelper.wrapButtonPress(
      onPressed: this,
      buttonName: buttonName,
      category: category,
      parameters: parameters,
    );
  }
}

// AnalyticsService'e erişim için helper sınıfı kaldırıldı - artık gerekli değilrişim için helper sınıfı kaldırıldı - artık gerekli değil