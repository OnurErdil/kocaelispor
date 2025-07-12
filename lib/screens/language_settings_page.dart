// lib/screens/language_settings_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/language_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';
import '../services/analytics_service.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: const CustomAppBar(
        title: "Dil Ayarları", // Sabit başlık - l10n kullanmayalım
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<LanguageProvider>(
          builder: (context, languageProvider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık
                Text(
                  languageProvider.isTurkish ? "Dil Ayarları" : "Language Settings",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Uygulamanın dilini seçin / Select the app language",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),

                // Dil seçenekleri
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildLanguageOption(
                          context: context,
                          languageProvider: languageProvider,
                          locale: const Locale('tr', 'TR'),
                          title: "Türkçe",
                          subtitle: "Turkish",
                          flag: "🇹🇷",
                        ),

                        const Divider(height: 32),

                        _buildLanguageOption(
                          context: context,
                          languageProvider: languageProvider,
                          locale: const Locale('en', 'US'),
                          title: "English",
                          subtitle: "İngilizce",
                          flag: "🇺🇸",
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Mevcut dil bilgisi
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
                        child: Text(
                          languageProvider.languageFlag,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              languageProvider.isTurkish ? "Aktif Dil" : "Active Language",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              languageProvider.languageName,
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
                          await languageProvider.toggleLanguage();

                          // Analytics eventi
                          await AnalyticsService.logEvent(
                            'language_quick_toggle',
                            parameters: {
                              'new_language': languageProvider.currentLocale.languageCode,
                            },
                          );
                        },
                        icon: const Icon(
                          Icons.swap_horiz,
                          color: AppTheme.primaryGreen,
                        ),
                        tooltip: languageProvider.isTurkish ? "Hızlı Değiştir" : "Quick Switch",
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Dil önizlemesi
                Text(
                  languageProvider.isTurkish ? "Önizleme" : "Preview",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                _buildLanguagePreview(context, languageProvider),

                const SizedBox(height: 24),

                // Bilgi kutusu
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
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
                          languageProvider.isTurkish
                              ? "Dil değişikliği anında uygulanır."
                              : "Language changes are applied instantly.",
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required LanguageProvider languageProvider,
    required Locale locale,
    required String title,
    required String subtitle,
    required String flag,
  }) {
    final isSelected = languageProvider.currentLocale.languageCode == locale.languageCode;

    return InkWell(
      onTap: () async {
        await languageProvider.setLanguage(locale);

        // Analytics eventi
        await AnalyticsService.logEvent(
          'language_changed',
          parameters: {
            'language_code': locale.languageCode,
            'previous_language': languageProvider.currentLocale.languageCode,
          },
        );

        // Feedback
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                languageProvider.isTurkish
                    ? "$title seçildi"
                    : "$title selected",
              ),
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
            // Bayrak
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
              child: Center(
                child: Text(
                  flag,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Dil bilgisi
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

            // Seçim göstergesi
            Radio<String>(
              value: locale.languageCode,
              groupValue: languageProvider.currentLocale.languageCode,
              onChanged: (value) async {
                if (value != null) {
                  await languageProvider.setLanguage(
                    LanguageProvider.getLocaleFromCode(value),
                  );
                }
              },
              activeColor: AppTheme.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguagePreview(BuildContext context, LanguageProvider languageProvider) {
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
          Text(
            languageProvider.isTurkish ? "Kocaelispor Fan Uygulaması" : "Kocaelispor Fan App",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
          const SizedBox(height: 8),

          // Alt başlık önizlemesi
          Text(
            languageProvider.isTurkish
                ? "En güncel haberler ve maç sonuçları"
                : "Latest news and match results",
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade600,
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
                    languageProvider.isTurkish ? "Kadroyu Gör" : "View Squad",
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
                  child: Text(
                    languageProvider.isTurkish ? "Haberler" : "News",
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// LanguageProvider için eksik metod
extension LanguageProviderExtension on LanguageProvider {
  static Locale getLocaleFromCode(String languageCode) {
    switch (languageCode) {
      case 'tr':
        return const Locale('tr', 'TR');
      case 'en':
        return const Locale('en', 'US');
      default:
        return const Locale('tr', 'TR');
    }
  }

  Future<void> toggleLanguage() async {
    if (isTurkish) {
      await setLanguage(const Locale('en', 'US'));
    } else {
      await setLanguage(const Locale('tr', 'TR'));
    }
  }
}