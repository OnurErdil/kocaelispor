// lib/widgets/language_toggle_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../provider/language_provider.dart';  // ✅ Doğru path: provider klasörü
import '../theme/app_theme.dart';

class LanguageToggleButton extends StatelessWidget {
  final double? iconSize;
  final Color? iconColor;

  const LanguageToggleButton({
    super.key,
    this.iconSize,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return IconButton(
          onPressed: () async {
            await languageProvider.toggleLanguage();

            // Başarı mesajı
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(languageProvider.languageFlag),
                      const SizedBox(width: 8),
                      Text(
                        "${languageProvider.languageName} ${languageProvider.isTurkish ? 'aktif' : 'active'}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                  duration: const Duration(seconds: 1),
                  backgroundColor: AppTheme.primaryGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(
                scale: animation,
                child: child,
              );
            },
            child: Text(
              languageProvider.languageFlag,
              key: ValueKey(languageProvider.currentLocale.languageCode),
              style: TextStyle(
                fontSize: iconSize ?? 20,
              ),
            ),
          ),
          tooltip: languageProvider.isTurkish
              ? "Dil: ${languageProvider.languageName}"
              : "Language: ${languageProvider.languageName}",
        );
      },
    );
  }
}

// Daha küçük widget versiyonu
class MiniLanguageToggle extends StatelessWidget {
  const MiniLanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return GestureDetector(
          onTap: () async {
            await languageProvider.toggleLanguage();
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              languageProvider.languageFlag,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        );
      },
    );
  }
}

// AppBar için bayrak butonu
class FlagLanguageButton extends StatelessWidget {
  const FlagLanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return Container(
          margin: const EdgeInsets.only(right: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                await languageProvider.toggleLanguage();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: Text(
                  languageProvider.languageFlag,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}