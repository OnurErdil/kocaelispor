// lib/utils/notification_helper.dart
import 'package:flutter/material.dart';

class NotificationHelper {
  // Başarı bildirimi
  static void showSuccessNotification(
      BuildContext context, {
        required String message,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white), // ✅ const eklendi
            const SizedBox(width: 8),                           // ✅ const eklendi
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),                  // ✅ const eklendi
      ),
    );
  }

  // Hata bildirimi
  static void showErrorNotification(
      BuildContext context, {
        required String message,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),      // ✅ const eklendi
            const SizedBox(width: 8),                          // ✅ const eklendi
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),                 // ✅ const eklendi
      ),
    );
  }

  // Forum mesajı bildirimi
  static void showForumMessageNotification(
      BuildContext context, {
        required String senderName,
        required String message,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.forum, color: Colors.white),     // ✅ const eklendi
            const SizedBox(width: 8),                         // ✅ const eklendi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(                                  // ✅ const eklendi
                    'Yeni Forum Mesajı',
                    style: TextStyle(fontWeight: FontWeight.bold), // ✅ const style
                  ),
                  Text(
                    '$senderName: ${message.length > 50 ? '${message.substring(0, 50)}...' : message}',
                    style: const TextStyle(fontSize: 12),     // ✅ const eklendi
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),              // ✅ const eklendi
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),                 // ✅ const eklendi
      ),
    );
  }

  // Uyarı bildirimi
  static void showWarningNotification(
      BuildContext context, {
        required String message,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),   // ✅ const eklendi
            const SizedBox(width: 8),                         // ✅ const eklendi
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),                // ✅ const eklendi
      ),
    );
  }

  // Bilgi bildirimi
  static void showInfoNotification(
      BuildContext context, {
        required String message,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),      // ✅ const eklendi
            const SizedBox(width: 8),                         // ✅ const eklendi
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),                // ✅ const eklendi
      ),
    );
  }
}