// lib/screens/admin_notification_panel.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// lib/screens/admin_notification_panel.dart - OVERFLOW DÜZELTİLDİ
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import '../services/admin_service.dart';

class AdminNotificationPanel extends StatefulWidget {
  const AdminNotificationPanel({super.key});

  @override
  State<AdminNotificationPanel> createState() => _AdminNotificationPanelState();
}

class _AdminNotificationPanelState extends State<AdminNotificationPanel> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  String _selectedType = 'Genel Duyuru';
  bool _isLoading = false;

  final List<String> _notificationTypes = [
    'Genel Duyuru',
    'Maç Bildirimi',
    'Transfer Haberi',
    'Kulüp Duyurusu',
    'Acil Bilgilendirme',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Push Bildirim Paneli",
      ),
      body: SafeArea( // ✅ SafeArea eklendi
        child: SingleChildScrollView( // ✅ Kaydırılabilir yapıldı
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Bildirim türü seçimi
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedType,
                            isExpanded: true,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            items: _notificationTypes.map((String type) {
                              return DropdownMenuItem<String>(
                                value: type,
                                child: Row(
                                  children: [
                                    Icon(_getTypeIcon(type), size: 20),
                                    const SizedBox(width: 8),
                                    Text(type),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedType = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Başlık
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bildirim Başlığı',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          hintText: 'Örn: Yeni Transfer!',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                          counterText: '', // ✅ Counter text gizlendi
                        ),
                        maxLength: 50,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // İçerik
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bildirim İçeriği',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _bodyController,
                        decoration: const InputDecoration(
                          hintText: 'Örn: Yeni transferimiz açıklandı!',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.message),
                          counterText: '', // ✅ Counter text gizlendi
                        ),
                        maxLines: 3,
                        maxLength: 150,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Önizleme kartı
              Card(
                elevation: 2,
                color: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.preview, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Bildirim Önizlemesi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.sports_soccer,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Kocaelispor',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'şimdi',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _titleController.text.isEmpty
                                  ? 'Bildirim başlığı buraya gelecek'
                                  : _titleController.text,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _bodyController.text.isEmpty
                                  ? 'Bildirim içeriği buraya gelecek'
                                  : _bodyController.text,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Test bildirimi butonu
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _sendTestNotification,
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Test Bildirimi Gönder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Herkese gönder butonu
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
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
                  label: Text(_isLoading ? 'Gönderiliyor...' : 'Tüm Kullanıcılara Gönder'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24), // ✅ Alt boşluk eklendi
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'Maç Bildirimi':
        return Icons.sports_soccer;
      case 'Transfer Haberi':
        return Icons.person_add;
      case 'Kulüp Duyurusu':
        return Icons.campaign;
      case 'Acil Bilgilendirme':
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  // Test bildirimi gönder
  Future<void> _sendTestNotification() async {
    if (_titleController.text.trim().isEmpty) {
      _showMessage('Lütfen başlık girin', isError: true);
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Test bildirimi gönder (sadece bu cihaza)
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

      // Firebase bildirim koleksiyonuna ekle
      await FirebaseFirestore.instance.collection('notifications').add({
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim().isEmpty
            ? 'Yeni bildirim'
            : _bodyController.text.trim(),
        'type': _selectedType,
        'timestamp': FieldValue.serverTimestamp(),
        'sentBy': 'admin',
      });

      // Admin aktivitesi logla
      await AdminService.logAdminActivity(
        action: 'NOTIFICATION_SENT',
        targetType: 'ALL_USERS',
        details: {
          'title': _titleController.text.trim(),
          'type': _selectedType,
        },
      );

      _showMessage('Bildirim başarıyla gönderildi!');
      _clearForm();

    } catch (e) {
      _showMessage('Bildirim gönderilemedi: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _showConfirmDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bildirim Gönder'),
        content: Text(
          'Tüm kullanıcılara "${_titleController.text.trim()}" bildirimi gönderilecek. Emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            child: const Text('Gönder', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  void _clearForm() {
    _titleController.clear();
    _bodyController.clear();
    setState(() {
      _selectedType = 'Genel Duyuru';
    });
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}