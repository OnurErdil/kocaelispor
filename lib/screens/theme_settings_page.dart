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
                            AppTheme.lightBackground,
                            AppTheme.lightSurface,
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
                            AppTheme.darkBackground,
                            AppTheme.darkSurface,
                            AppTheme.darkCardColor,
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
                            AppTheme.primaryDark,
                            AppTheme.primaryLight,
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

                          // Analytics eventi
                          AnalyticsService._analytics.logEvent(
                            name: 'theme_quick_toggle',
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

                _buildThemePreview(context),
              ],
            );
          },
        ),
      ),
    );