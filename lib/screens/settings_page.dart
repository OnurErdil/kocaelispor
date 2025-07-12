// lib/screens/settings_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';
import '../services/connectivity_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with ConnectivityMixin {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  bool _autoRefreshEnabled = true;
  String _selectedLanguage = 'Türkçe';
  int _refreshInterval = 30; // saniye

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _darkModeEnabled = prefs.getBool('dark_mode_enabled') ?? false;
        _autoRefreshEnabled = prefs.getBool('auto_refresh_enabled') ?? true;
        _selectedLanguage = prefs.getString('selected_language') ?? 'Türkçe';
        _refreshInterval = prefs.getInt('refresh_interval') ?? 30;
      });
    } catch (e) {
      print('Ayarlar yüklenirken hata: $e');
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      }
    } catch (e) {
      print('Ayar kaydedilirken hata: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Ayarlar",
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Bağlantı durumu
          if (!isOnline)
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.orange.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Çevrimdışı Mod',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                          Text(
                            'Bazı ayarlar internet bağlantısı gerektiriyor',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Genel Ayarlar
          _buildSectionHeader('Genel'),
          _buildSettingsCard([
            _buildSwitchTile(
              title: 'Bildirimler',
              subtitle: 'Yeni haberler ve maç sonuçları için bildirim al',
              icon: Icons.notifications,
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                _saveSetting('notifications_enabled', value);
              },
            ),
            _buildSwitchTile(
              title: 'Otomatik Yenileme',
              subtitle: 'Sayfalar otomatik olarak yenilensin',
              icon: Icons.refresh,
              value: _autoRefreshEnabled,
              onChanged: (value) {
                setState(() => _autoRefreshEnabled = value);
                _saveSetting('auto_refresh_enabled', value);
              },
            ),
            _buildListTile(
              title: 'Yenileme Aralığı',
              subtitle: '$_refreshInterval saniye',
              icon: Icons.timer,
              onTap: () => _showRefreshIntervalDialog(),
            ),
          ]),

          const SizedBox(height: 16),

          // Görünüm
          _buildSectionHeader('Görünüm'),
          _buildSettingsCard([
            _buildSwitchTile(
              title: 'Koyu Tema',
              subtitle: 'Gece modunu etkinleştir',
              icon: Icons.dark_mode,
              value: _darkModeEnabled,
              onChanged: (value) {
                setState(() => _darkModeEnabled = value);
                _saveSetting('dark_mode_enabled', value);
                _showThemeDialog();
              },
            ),
            _buildListTile(
              title: 'Dil',
              subtitle: _selectedLanguage,
              icon: Icons.language,
              onTap: () => _showLanguageDialog(),
            ),
          ]),

          const SizedBox(height: 16),

          // Uygulama Bilgileri
          _buildSectionHeader('Uygulama'),
          _buildSettingsCard([
            _buildListTile(
              title: 'Önbelleği Temizle',
              subtitle: 'Geçici dosyaları sil',
              icon: Icons.cleaning_services,
              onTap: () => _showClearCacheDialog(),
            ),
            _buildListTile(
              title: 'Geri Bildirim Gönder',
              subtitle: 'Önerilerinizi bizimle paylaşın',
              icon: Icons.feedback,
              onTap: () => _showFeedbackDialog(),
            ),
            _buildListTile(
              title: 'Hakkında',
              subtitle: 'Uygulama bilgileri ve sürüm',
              icon: Icons.info,
              onTap: () => _showAboutDialog(),
            ),
          ]),

          const SizedBox(height: 16),

          // Gelişmiş
          _buildSectionHeader('Gelişmiş'),
          _buildSettingsCard([
            _buildListTile(
              title: 'Bağlantı Testi',
              subtitle: 'İnternet bağlantısını test et',
              icon: Icons.network_check,
              onTap: () => _testConnection(),
            ),
            _buildListTile(
              title: 'Ayarları Sıfırla',
              subtitle: 'Tüm ayarları varsayılana döndür',
              icon: Icons.restore,
              onTap: () => _showResetDialog(),
              textColor: Colors.red.shade600,
            ),
          ]),

          const SizedBox(height: 32),

          // Kocaelispor bilgisi
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sports_soccer,
                      color: AppTheme.primaryGreen,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Kocaelispor 1966',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sürüm 1.0.0',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryGreen,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      secondary: Icon(icon, color: AppTheme.primaryGreen),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryGreen,
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(color: textColor),
      ),
      subtitle: Text(subtitle),
      leading: Icon(icon, color: textColor ?? AppTheme.primaryGreen),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showRefreshIntervalDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yenileme Aralığı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [10, 30, 60, 120, 300].map((seconds) {
            return RadioListTile<int>(
              title: Text('${seconds ~/ 60 > 0 ? '${seconds ~/ 60} dakika' : '$seconds saniye'}'),
              value: seconds,
              groupValue: _refreshInterval,
              onChanged: (value) {
                setState(() => _refreshInterval = value!);
                _saveSetting('refresh_interval', value);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dil Seçin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Türkçe', 'English'].map((language) {
            return RadioListTile<String>(
              title: Text(language),
              value: language,
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() => _selectedLanguage = value!);
                _saveSetting('selected_language', value);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemeDialog() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _darkModeEnabled
              ? 'Koyu tema etkinleştirildi (Uygulama yeniden başlatılmalı)'
              : 'Açık tema etkinleştirildi',
        ),
        action: SnackBarAction(
          label: 'Tamam',
          onPressed: () {},
        ),
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Önbelleği Temizle'),
        content: const Text(
          'Bu işlem geçici dosyaları ve önbelleği temizleyecek. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Önbellek temizleme işlemi
              await _clearCache();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearCache() async {
    try {
      // Shared Preferences'tan geçici verileri temizle
      final prefs = await SharedPreferences.getInstance();
      final keysToRemove = prefs.getKeys().where((key) =>
      key.startsWith('cache_') || key.startsWith('temp_')
      ).toList();

      for (final key in keysToRemove) {
        await prefs.remove(key);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Önbellek başarıyla temizlendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Önbellek temizlenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFeedbackDialog() {
    final feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Geri Bildirim'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Önerileriniz bizim için çok değerli. Lütfen düşüncelerinizi paylaşın:',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: feedbackController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Geri bildiriminizi buraya yazın...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendFeedback(feedbackController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }

  void _sendFeedback(String feedback) {
    if (feedback.trim().isEmpty) return;

    // Burada feedback'i sunucuya gönderebilir veya e-posta olarak iletebilirsiniz
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Geri bildiriminiz için teşekkürler!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Kocaelispor 1966',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.sports_soccer,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: [
        const Text(
          'Kocaelispor taraftarları için geliştirilmiş resmi olmayan mobil uygulama.',
        ),
        const SizedBox(height: 16),
        const Text('Özellikler:'),
        const Text('• Canlı maç sonuçları'),
        const Text('• Kadro bilgileri'),
        const Text('• Son haberler'),
        const Text('• Fotoğraf galerisi'),
        const Text('• Puan durumu'),
        const SizedBox(height: 16),
        Text(
          'Geliştirici: Flutter Developer',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Future<void> _testConnection() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Bağlantı test ediliyor...'),
          ],
        ),
      ),
    );

    try {
      final isConnected = await ConnectivityService().checkConnectivity();

      if (mounted) {
        Navigator.pop(context); // Loading dialog'u kapat

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  isConnected ? Icons.check_circle : Icons.error,
                  color: isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(isConnected ? 'Bağlantı Başarılı' : 'Bağlantı Hatası'),
              ],
            ),
            content: Text(
              isConnected
                  ? 'İnternet bağlantınız çalışıyor.'
                  : 'İnternet bağlantısı bulunamadı. Lütfen Wi-Fi veya mobil veri bağlantınızı kontrol edin.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Test sırasında hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ayarları Sıfırla'),
        content: const Text(
          'Bu işlem tüm ayarları varsayılan değerlere döndürecek. Bu işlem geri alınamaz. Devam etmek istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resetAllSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetAllSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Sadece ayar anahtarlarını sil, diğer verileri koru
      final settingsKeys = [
        'notifications_enabled',
        'dark_mode_enabled',
        'auto_refresh_enabled',
        'selected_language',
        'refresh_interval',
      ];

      for (final key in settingsKeys) {
        await prefs.remove(key);
      }

      // Ayarları varsayılana döndür
      setState(() {
        _notificationsEnabled = true;
        _darkModeEnabled = false;
        _autoRefreshEnabled = true;
        _selectedLanguage = 'Türkçe';
        _refreshInterval = 30;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ayarlar başarıyla sıfırlandı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ayarlar sıfırlanırken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void onConnectionRestored() {
    super.onConnectionRestored();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi, color: Colors.white),
            SizedBox(width: 8),
            Text('İnternet bağlantısı geri geldi'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void onConnectionLost() {
    super.onConnectionLost();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white),
            SizedBox(width: 8),
            Text('İnternet bağlantısı kesildi'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
      ),
    );
  }
}