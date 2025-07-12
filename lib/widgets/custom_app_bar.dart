// lib/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'theme_toggle_button.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool showThemeToggle; // ✅ Yeni parametre
  final VoidCallback? onBackPressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBackButton = true,
    this.showThemeToggle = false, // ✅ Varsayılan false
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Actions listesini hazırla
    List<Widget> allActions = [];

    // Tema değiştirme butonu varsa ekle
    if (showThemeToggle) {
      allActions.add(const ThemeToggleButton());
    }

    // Mevcut actions varsa ekle
    if (actions != null) {
      allActions.addAll(actions!);
    }

    return AppBar(
      title: Text(title),
      backgroundColor: AppTheme.primaryGreen,
      foregroundColor: Colors.white,
      leading: showBackButton
          ? IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: onBackPressed ?? () => Navigator.pop(context),
      )
          : null,
      actions: allActions.isNotEmpty ? allActions : null,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}