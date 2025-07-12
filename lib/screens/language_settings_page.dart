// lib/screens/language_settings_page.dart
import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../theme/app_theme.dart';

class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  String selectedLanguage = 'tr'; // Seçili dil

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Dil Ayarları",
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Text(
              "Dil Ayarları",
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
                      locale: 'tr',
                      title: "Türkçe",
                      subtitle: "Turkish",
                      flag: "🇹🇷",
                    ),

                    const Divider(height: 32),

                    _buildLanguageOption(
                      locale: 'en',
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
                    child: Text(
                      selectedLanguage == 'tr' ? "🇹🇷" : "🇺🇸",
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Aktif Dil",
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          selectedLanguage == 'tr' ? "Türkçe" : "English",
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
                        selectedLanguage = selectedLanguage == 'tr' ? 'en' : 'tr';
                      });

                      // Kullanıcıya bilgi ver
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            selectedLanguage == 'tr'
                                ? "Türkçe seçildi"
                                : "English selected",
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.swap_horiz,
                      color: AppTheme.primaryGreen,
                    ),
                    tooltip: "Hızlı Değiştir",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Dil önizlemesi
            Text(
              "Önizleme",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            _buildLanguagePreview(),

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
                      "Dil değişikliği anında uygulanır.",
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

  // Dil seçeneği widget'ı
  Widget _buildLanguageOption({
    required String locale,
    required String title,
    required String subtitle,
    required String flag,
  }) {
    final isSelected = selectedLanguage == locale;

    return InkWell(
      onTap: () {
        setState(() {
          selectedLanguage = locale;
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
            // Bayrak
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryGreen.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
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
              value: locale,
              groupValue: selectedLanguage,
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedLanguage = value;
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
              activeColor: AppTheme.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }

  // Dil önizleme widget'ı
  Widget _buildLanguagePreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.withValues(alpha: 0.1),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedLanguage == 'tr'
                ? "Kocaelispor Fan Uygulaması"
                : "Kocaelispor Fan App",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedLanguage == 'tr'
                ? "Ana Sayfa • Takım • Fikstür"
                : "Home • Team • Fixtures",
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            selectedLanguage == 'tr'
                ? "Hoş Geldiniz"
                : "Welcome",
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}