// lib/widgets/theme_toggle_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart' as providers;
import '../theme/app_theme.dart';

class ThemeToggleButton extends StatelessWidget {
  final double? iconSize;
  final Color? iconColor;

  const ThemeToggleButton({
    super.key,
    this.iconSize,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<providers.ThemeProvider>(
      builder: (context, themeProvider, child) {
        return IconButton(
          onPressed: () async {
            await themeProvider.toggleTheme();

            // Başarı mesajı (opsiyonel)
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "${themeProvider.themeDescription} aktif",
                    style: const TextStyle(color: Colors.white),
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
              return RotationTransition(
                turns: animation,
                child: child,
              );
            },
            child: Icon(
              themeProvider.themeIcon,
              key: ValueKey(themeProvider.themeMode),
              size: iconSize ?? 24,
              color: iconColor ?? Colors.white,
            ),
          ),
          tooltip: "Tema: ${themeProvider.themeDescription}",
        );
      },
    );
  }
}

// Daha küçük widget versiyonu (bottom navigation için)
class MiniThemeToggle extends StatelessWidget {
  const MiniThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<providers.ThemeProvider>(
      builder: (context, themeProvider, child) {
        return GestureDetector(
          onTap: () async {
            await themeProvider.toggleTheme();
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              themeProvider.themeIcon,
              size: 16,
              color: AppTheme.primaryGreen,
            ),
          ),
        );
      },
    );
  }
}