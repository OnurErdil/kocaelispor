import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'anasayfa.dart';
import 'kadro_sayfasi.dart';
import 'profile_page.dart';
import 'takvim_sayfasi.dart';
import 'galeri_sayfasi.dart'; // ✅ YENİ IMPORT

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;

  final List<Widget> _pages = [
    const Anasayfa(),
    const KadroSayfasi(),
    const TakvimSayfasi(),
    const GaleriSayfasi(), // ✅ YENİ SAYFA
    const ProfilePage(),
  ];

  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Ana Sayfa',
    ),
    _NavItem(
      icon: Icons.people_outline,
      activeIcon: Icons.people,
      label: 'Kadro',
    ),
    _NavItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: 'Takvim',
    ),
    _NavItem(
      icon: Icons.photo_library_outlined, // ✅ YENİ İKON
      activeIcon: Icons.photo_library,
      label: 'Galeri',
    ),
    _NavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profil',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      // Aynı tab'a tekrar tıklandığında hafif titreşim
      HapticFeedback.lightImpact();
      return;
    }

    setState(() {
      _currentIndex = index;
    });

    // Sayfa geçişi animasyonu
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    // Hafif titreşim feedback
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        children: _pages,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            type: BottomNavigationBarType.fixed, // 4 item için gerekli
            backgroundColor: const Color(0xFF1A1A1A), // Daha modern koyu ton
            selectedItemColor: const Color(0xFF00913C), // Kocaelispor yeşili
            unselectedItemColor: Colors.grey.shade400,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 11,
            ),
            onTap: _onTabTapped,
            items: _navItems.map((item) {
              final isSelected = _navItems.indexOf(item) == _currentIndex;
              return BottomNavigationBarItem(
                icon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF00913C).withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isSelected ? item.activeIcon : item.icon,
                    size: isSelected ? 26 : 24,
                  ),
                ),
                label: item.label,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// Bonus: Kocaelispor teması için ortak renk sabitleri
class KocaelisporTheme {
  static const Color primaryGreen = Color(0xFF00913C);
  static const Color darkGreen = Color(0xFF006B2D);
  static const Color lightGreen = Color(0xFF4CAF50);
  static const Color darkBackground = Color(0xFF1A1A1A);
  static const Color cardBackground = Color(0xFF2D2D2D);

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primarySwatch: MaterialColor(0xFF00913C, {
      50: const Color(0xFFE8F5E8),
      100: const Color(0xFFC8E6C9),
      200: const Color(0xFFA5D6A7),
      300: const Color(0xFF81C784),
      400: const Color(0xFF66BB6A),
      500: primaryGreen,
      600: const Color(0xFF43A047),
      700: darkGreen,
      800: const Color(0xFF2E7D32),
      900: const Color(0xFF1B5E20),
    }),
    scaffoldBackgroundColor: darkBackground,
    cardColor: cardBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryGreen, width: 2),
      ),
    ),
  );
}