// lib/screens/admin_notification_panel.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class AdminNotificationPanel extends StatefulWidget {
  const AdminNotificationPanel({super.key});

  @override
  State<AdminNotificationPanel> createState() => _AdminNotificationPanelState();
}

class _AdminNotificationPanelState extends State<AdminNotificationPanel> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedType = 'genel';
  bool _isLoading = false;

  // Bildirim türleri
  final Map<String, String> _notificationTypes = {
    'genel': '📢 Genel Duyuru',
    'mac': '⚽ Maç Bildirimi',
    'transfer': '🔄 Transfer Haberi',
    'gol': '⚽ Gol Bildirimi',
    'haber': '📰 Yeni Haber',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Gönder'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bildirim türü seçimi
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bildirim Türü',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _notificationTypes.entries.map((entry) {
                        return DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Başlık
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Bildirim Başlığı',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                    hintText: 'Örn: Yeni Transfer!',
                  ),
                  maxLength: 50,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // İçerik
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _bodyController,
                  decoration: const InputDecoration(
                    labelText: 'Bildirim İçeriği',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.message),
                    hintText: 'Örn: Yeni transferimiz açıklandı!',
                  ),
                  maxLines: 3,
                  maxLength: 150,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Test bildirimi butonu
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendTestNotification,
              icon: const Icon(Icons.bug_report),
              label: const Text('Test Bildirimi Gönder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),

            // Herkese gönder butonu
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _sendToAllUsers,
              icon: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.send),
              label: Text(_isLoading ? 'Gönderiliyor...' : 'Herkese Gönder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            // Bilgi kartı
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Bilgilendirme',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Test bildirimi sadece bu cihaza gelir\n'
                          '• "Herkese Gönder" tüm kullanıcılara bildirim gönderir\n'
                          '• Bildirimler 5-10 saniye içinde ulaşır',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Test bildirimi gönder
  Future<void> _sendTestNotification() async {
    if (_titleController.text.trim().isEmpty) {
      _showMessage('Lütfen başlık girin', isError: true);
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Local notification göster
      await NotificationService.showLocalNotification(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim().isEmpty
            ? 'Test bildirimi'
            : _bodyController.text.trim(),
        payload: 'test_notification',
        id: DateTime.now().millisecondsSinceEpoch,
      );

      _showMessage('Test bildirimi gönderildi!');

    } catch (e) {
      _showMessage('Test bildirimi gönderilemedi: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Tüm kullanıcılara bildirim gönder
  Future<void> _sendToAllUsers() async {
    if (_titleController.text.trim().isEmpty) {
      _showMessage('Lütfen başlık girin', isError: true);
      return;
    }

    final confirmed = await _showConfirmDialog();
    if (!confirmed) return;

    try {
      setState(() => _isLoading = true);

      // ⚠️ ÖNEMLI: Bu kısım Firebase Console üzerinden yapılmalı
      // Çünkü server key gerekli. Bu kod sadece örnek amaçlı.

      await _sendNotificationViaFirebase(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim().isEmpty
            ? 'Yeni bildirim'
            : _bodyController.text.trim(),
        type: _selectedType,
      );

    } catch (e) {
      _showMessage('Bildirim gönderilemedi: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Firebase üzerinden bildirim gönder (örnek)
  Future<void> _sendNotificationViaFirebase({
    required String title,
    required String body,
    required String type,
  }) async {
    // ⚠️ UYARI: Bu kod çalışmaz çünkü server key gerekli
    // Gerçek uygulamada backend sunucunuzdan göndermelisiniz

    const String serverKey = 'YOUR_SERVER_KEY_HERE'; // Firebase Console'dan alın
    const String fcmUrl = 'https://fcm.googleapis.com/fcm/send';

    final Map<String, dynamic> notification = {
      'to': '/topics/all_users', // Tüm kullanıcılar için topic
      'notification': {
        'title': title,
        'body': body,
        'icon': '@mipmap/ic_launcher',
        'sound': 'default',
      },
      'data': {
        'type': type,
        'timestamp': DateTime.now().toIso8601String(),
      },
    };

    try {
      final response = await http.post(
        Uri.parse(fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode(notification),
      );

      if (response.statusCode == 200) {
        _showMessage('Bildirim başarıyla gönderildi!');
        _clearFields();
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Bildirim gönderme hatası: $e');

      // Alternatif: Firebase Console kullanma talimatı göster
      _showFirebaseConsoleInfo();
    }
  }

  // Firebase Console bilgisi göster
  void _showFirebaseConsoleInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Firebase Console Kullanın'),
        content: const Text(
            'Şu an için Firebase Console üzerinden bildirim gönderin:\n\n'
                '1. Firebase Console > Messaging\n'
                '2. "Send your first message"\n'
                '3. Başlık ve içeriği girin\n'
                '4. "kocaelispor_1966_mobil" uygulamasını seçin\n'
                '5. "Send message"'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  // Onay dialogu
  Future<bool> _showConfirmDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bildirim Gönder'),
        content: const Text('Bu bildirim tüm kullanıcılara gönderilecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
            child: const Text('Gönder'),
          ),
        ],
      ),
    ) ?? false;
  }

  // Mesaj göster
  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // Form alanlarını temizle
  void _clearFields() {
    _titleController.clear();
    _bodyController.clear();
    setState(() => _selectedType = 'genel');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }
}