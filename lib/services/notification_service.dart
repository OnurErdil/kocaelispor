// lib/services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Basit in-app bildirim gösterme
  static void showInAppNotification(
      BuildContext context, {
        required String title,
        required String message,
        IconData icon = Icons.notifications,
        Color backgroundColor = const Color(0xFF00913C),
        Duration duration = const Duration(seconds: 4),
      }) {
    // Haptic feedback
    HapticFeedback.lightImpact();

    // Overlay ile bildirim göster
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // İkon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Metin
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Kapatma butonu
                GestureDetector(
                  onTap: () => overlayEntry.remove(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Overlay'e ekle
    overlay.insert(overlayEntry);

    // Belirli süre sonra otomatik kaldır
    Future.delayed(duration, () {
      try {
        overlayEntry.remove();
      } catch (e) {
        // Zaten kaldırılmış olabilir
      }
    });
  }

  // Forum mesajı bildirimi
  static void showForumMessageNotification(
      BuildContext context, {
        required String senderName,
        required String message,
      }) {
    showInAppNotification(
      context,
      title: 'Yeni Forum Mesajı',
      message: '$senderName: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}',
      icon: Icons.forum,
      backgroundColor: const Color(0xFF00913C),
    );
  }

  // Genel bildirim
  static void showSuccessNotification(
      BuildContext context, {
        required String message,
      }) {
    showInAppNotification(
      context,
      title: 'Başarılı!',
      message: message,
      icon: Icons.check_circle,
      backgroundColor: Colors.green,
    );
  }

  // Hata bildirimi
  static void showErrorNotification(
      BuildContext context, {
        required String message,
      }) {
    showInAppNotification(
      context,
      title: 'Hata!',
      message: message,
      icon: Icons.error,
      backgroundColor: Colors.red,
    );
  }

  // Uyarı bildirimi
  static void showWarningNotification(
      BuildContext context, {
        required String message,
      }) {
    showInAppNotification(
      context,
      title: 'Uyarı!',
      message: message,
      icon: Icons.warning,
      backgroundColor: Colors.orange,
    );
  }

  // Takım bildirimi (maç sonucu vs.)
  static void showTeamNotification(
      BuildContext context, {
        required String title,
        required String message,
      }) {
    showInAppNotification(
      context,
      title: title,
      message: message,
      icon: Icons.sports_soccer,
      backgroundColor: const Color(0xFF00913C),
    );
  }
}