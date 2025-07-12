// lib/screens/theme_settings_page.dart
import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';

class ThemeSettingsPage extends StatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  String selectedTheme = 'light'; // light, dark, system

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Tema Ayarları",
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Text(
              "Görünüm Tercihi",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Uygulamanın görünümünü kişiselleştirin",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),

            // Tema seçenekleri
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildThemeOption(
                      theme: 'light',
                      title: "Açık Tema",
                      subtitle: "Parlak renk teması",
                      icon: Icons.light_mode,
                      color: Colors.orange,
                    ),

                    const Divider(height: 32),

                    _buildThemeOption(
                      theme: 'dark',
                      title: "Koyu Tema",
                      subtitle: "Karanlık renk teması",
                      icon: Icons.dark_mode,
                      color: Colors.purple,
                    ),

                    const Divider(height: 32),

                    _buildThemeOption(
                      theme: 'system',
                      title: "Sistem Teması",
                      subtitle: "Cihaz ayarını takip eder",
                      icon: Icons.settings,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Mevcut tema bilgisi
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getThemeIcon(),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Aktif Tema",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _getThemeDescription(),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Hızlı değiştirme butonu
                  IconButton(
                    onPressed: () {
                      setState(() {
                        if (selectedTheme == 'light') {
                          selectedTheme = 'dark';
                        } else if (selectedTheme == 'dark') {
                          selectedTheme = 'system';
                        } else {
                          selectedTheme = 'light';
                        }
                      });

                      // Kullanıcıya bilgi ver
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("${_getThemeDescription()} seçildi"),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.refresh,
                      color: AppTheme.primaryGreen,
                    ),
                    tooltip: "Hızlı Değiştir",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tema önizleme
            Text(
              "Önizleme",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _buildThemePreview(),

            const SizedBox(height: 24),

            // Bilgi kutusu
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Tema değişikliği uygulama yeniden başlatıldığında etkili olur.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tema seçeneği widget'ı
  Widget _buildThemeOption({
    required String theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = selectedTheme == theme;

    return InkWell(
      onTap: () {
        setState(() {
          selectedTheme = theme;
        });

        // Kullanıcıya bilgi ver
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$title seçildi"),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Tema ikonu
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected ? color : Colors.grey.shade600,
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            // Tema bilgisi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Seçim göstergesi
            Radio<String>(
              value: theme,
              groupValue: selectedTheme,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedTheme = value;
                  });

                  // Kullanıcıya bilgi ver
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("$title seçildi"),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }

  // Tema önizleme widget'ı
  Widget _buildThemePreview() {
    Color previewBg;
    Color previewText;
    Color previewCard;

    switch (selectedTheme) {
      case 'dark':
        previewBg = Colors.grey.shade900;
        previewText = Colors.white;
        previewCard = Colors.grey.shade800;
        break;
      case 'light':
        previewBg = Colors.white;
        previewText = Colors.black;
        previewCard = Colors.grey.shade100;
        break;
      case 'system':
      default:
      // Mevcut tema moduna göre
        final brightness = Theme.of(context).brightness;
        if (brightness == Brightness.dark) {
          previewBg = Colors.grey.shade900;
          previewText = Colors.white;
          previewCard = Colors.grey.shade800;
        } else {
          previewBg = Colors.white;
          previewText = Colors.black;
          previewCard = Colors.grey.shade100;
        }
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: previewBg,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "Kocaelispor",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // İçerik kartı
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: previewCard,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sports_soccer,
                  color: previewText,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Maç Sonucu",
                        style: TextStyle(
                          color: previewText,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "Kocaelispor 2-1 Rakip",
                        style: TextStyle(
                          color: previewText.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Aktif tema ikonu
  IconData _getThemeIcon() {
    switch (selectedTheme) {
      case 'light':
        return Icons.light_mode;
      case 'dark':
        return Icons.dark_mode;
      case 'system':
        return Icons.settings;
      default:
        return Icons.light_mode;
    }
  }

  // Aktif tema açıklaması
  String _getThemeDescription() {
    switch (selectedTheme) {
      case 'light':
        return "Açık Tema";
      case 'dark':
        return "Koyu Tema";
      case 'system':
        return "Sistem Teması";
      default:
        return "Açık Tema";
    }
  }
}