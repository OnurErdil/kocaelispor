// lib/widgets/analytics_wrapper.dart
import 'package:flutter/material.dart';
import '../services/analytics_service.dart';

class AnalyticsWrapper extends StatefulWidget {
  final Widget child;
  final String screenName;
  final VoidCallback? onScreenView;

  const AnalyticsWrapper({
    super.key,
    required this.child,
    required this.screenName,
    this.onScreenView,
  });

  @override
  State<AnalyticsWrapper> createState() => _AnalyticsWrapperState();
}

class _AnalyticsWrapperState extends State<AnalyticsWrapper> {
  @override
  void initState() {
    super.initState();
    // Sayfa yüklendiğinde analytics başlat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.startScreenTime(widget.screenName);
      widget.onScreenView?.call();
    });
  }

  @override
  void dispose() {
    // Sayfa kapanırken analytics bitir
    AnalyticsService.endScreenTime(widget.screenName);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Kolay kullanım için helper metodlar
class AnalyticsHelper {
  // Sayfa wrapper'ı
  static Widget wrapScreen({
    required Widget child,
    required String screenName,
    VoidCallback? onScreenView,
  }) {
    return AnalyticsWrapper(
      screenName: screenName,
      onScreenView: onScreenView,
      child: child,
    );
  }

  // Buton tıklama analytics'i
  static VoidCallback wrapButtonPress({
    required VoidCallback onPressed,
    required String buttonName,
    String? category,
  }) {
    return () {
      // Analytics eventi kaydet
      AnalyticsService._analytics.logEvent(
        name: 'button_click',
        parameters: {
          'button_name': buttonName,
          'category': category ?? 'general',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      // Orijinal fonksiyonu çalıştır
      onPressed();
    };
  }
}