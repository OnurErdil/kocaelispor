// lib/screens/main_screen.dart - DÜZELTILMIŞ VERSİYON
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'anasayfa.dart';
import 'kadro_sayfasi.dart';
import 'profile_page.dart';
import 'takvim_sayfasi.dart';
import 'galeri_sayfasi.dart';
import 'forum_sayfasi.dart';
import 'package:provider/provider.dart';
import '../providers/tab_provider.dart';

final GlobalKey<_MainScreenState> mainScreenKey = GlobalKey<_MainScreenState>();

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _animationController;

  // ✅ SAYFALAR LİSTESİ (6 ADET)
  final List<Widget> _pages = [
    const Anasayfa(),        // 0
    const KadroSayfasi(),    // 1
    const TakvimSayfasi(),   // 2
    const ForumSayfasi(),    // 3
    const GaleriSayfasi(),   // 4
    const ProfilePage(),     // 5
  ];

  // ✅ NAVIGASYON İTEMLERİ (6 ADET)
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
      label: 'Fikstür',
    ),
    _NavItem(
      icon: Icons.forum_outlined,
      activeIcon: Icons.forum,
      label: 'Forum',
    ),
    _NavItem(
      icon: Icons.photo_library_outlined,
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TabProvider>().setPageController(_pageController);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ✅ DÜZELTILMIŞ TAB DEĞİŞTİRME FONKSİYONU
  void _onTabTapped(int index) {
    print("🔄 Tab değiştiriliyor: $_currentIndex -> $index");

    if (_currentIndex == index) {
      // Aynı tab'a tekrar tıklandığında hafif titreşim
      HapticFeedback.lightImpact();
      return;
    }

    // ✅ ÖNEMLİ: setState ve sayfa değiştirme işlemini birlikte yap
    setState(() {
      _currentIndex = index;
    });

    // ✅ SAYFA GEÇİŞİ ANİMASYONU
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );

    // Hafif titreşim feedback
    HapticFeedback.selectionClick();

    print("✅ Tab değiştirildi: $index");
  }

  // ✅ ALTERNATIF TAB DEĞİŞTİRME FONKSİYONU (provider ile)
  void changeTab(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });

      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped, // ✅ DÜZELTILMIŞ FONKSİYON
          type: BottomNavigationBarType.fixed, // ✅ 6 ITEM İÇİN GEREKLİ
          backgroundColor: const Color(0xFF1A1A1A), // Koyu tema
          selectedItemColor: const Color(0xFF00913C), // Kocaelispor yeşili
          unselectedItemColor: Colors.grey.shade400,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 10,
          ),
          elevation: 8,
          items: _navItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = _currentIndex == index;

            return BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00913C).withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isSelected ? item.activeIcon : item.icon,
                  size: 24,
                ),
              ),
              label: item.label,
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ✅ NAVİGASYON İTEM SINIFI
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