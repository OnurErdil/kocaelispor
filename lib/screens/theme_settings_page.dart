// lib/screens/theme_settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart' as providers;
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';
import '../services/analytics_service.dart';

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: "Tema Ayarları",
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<providers.ThemeProvider>(
          builder: (context, themeProvider, child) {
            return Column(
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
                          context: context,
                          themeProvider: themeProvider,
                          themeMode: providers.ThemeMode.light,
                          title: "Açık Tema",
                          subtitle: "Parlak ve temiz görünüm",
                          icon: Icons.light_mode,
                          previewColors: [
                            Colors.white,
                            Colors.grey.shade50,
                            Colors.grey.shade100,
                          ],
                        ),

                        const Divider(height: 24),

                        _buildThemeOption(
                          context: context,
                          themeProvider: themeProvider,
                          themeMode: providers.ThemeMode.dark,
                          title: "Koyu Tema",
                          subtitle: "Göz dostu karanlık görünüm",
                          icon: Icons.dark_mode,
                          previewColors: [
                            Colors.grey.shade900,
                            Colors.grey.shade800,
                            Colors.grey.shade700,
                          ],
                        ),

                        const Divider(height: 24),

                        _buildThemeOption(
                          context: context,
                          themeProvider: themeProvider,
                          themeMode: providers.ThemeMode.system,
                          title: "Sistem Teması",
                          subtitle: "Cihaz ayarlarını takip eder",
                          icon: Icons.brightness_auto,
                          previewColors: [
                            AppTheme.primaryGreen,
                            AppTheme.primaryGreen.withOpacity(0.7),
                            AppTheme.primaryGreen.withOpacity(0.4),
                          ],
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
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.3),
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
                          themeProvider.themeIcon,
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
                              themeProvider.themeDescription,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Hızlı değiştirme butonu
                      IconButton(
                        onPressed: () async {
                          await themeProvider.toggleTheme();

                          // Analytics eventi - düzeltilmiş
                          await AnalyticsService.logEvent(
                            'theme_quick_toggle',
                            parameters: {
                              'new_theme': themeProvider.themeMode.toString(),
                            },
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

                _buildThemePreview(context, themeProvider),
              ],
            );
          },
        ),
      ),
    );
  }

  // ✅ EKSIK METOD: _buildThemeOption
  Widget _buildThemeOption({
    required BuildContext context,
    required providers.ThemeProvider themeProvider,
    required providers.ThemeMode themeMode,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> previewColors,
  }) {
    final isSelected = themeProvider.themeMode == themeMode;

    return InkWell(
      onTap: () async {
        await themeProvider.setThemeMode(themeMode);

        // Analytics eventi
        await AnalyticsService.logEvent(
          'theme_changed',
          parameters: {
            'theme_mode': themeMode.toString(),
            'previous_theme': themeProvider.themeMode.toString(),
          },
        );

        // Feedback
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("$title seçildi"),
              duration: const Duration(seconds: 2),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
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
                    ? AppTheme.primaryGreen.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryGreen
                      : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.primaryGreen : Colors.grey.shade600,
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
                      color: isSelected ? AppTheme.primaryGreen : null,
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

            // Renk önizlemesi
            Row(
              children: previewColors.map((color) {
                return Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 0.5,
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(width: 12),

            // Seçim göstergesi
            Radio<providers.ThemeMode>(
              value: themeMode,
              groupValue: themeProvider.themeMode,
              onChanged: (value) async {
                if (value != null) {
                  await themeProvider.setThemeMode(value);
                }
              },
              activeColor: AppTheme.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ EKSIK METOD: _buildThemePreview
  Widget _buildThemePreview(BuildContext context, providers.ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık önizlemesi
          Row(
            children: [
              Icon(
                Icons.sports_soccer,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Kocaelispor",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // İçerik önizlemesi
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Son Haberler",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Kocaelispor'dan transfer haberleri...",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Buton önizlemesi
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: null, // Önizleme için deaktif
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primaryGreen),
                  ),
                  child: Text(
                    "Takım",
                    style: TextStyle(color: AppTheme.primaryGreen),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: null, // Önizleme için deaktif
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Haberler"),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Tema açıklaması
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  themeProvider.themeIcon,
                  color: AppTheme.primaryGreen,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  "${themeProvider.themeDescription} aktif",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}