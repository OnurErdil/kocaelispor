// lib/screens/main_screen.dart - GÜNCELLENMİŞ VERSİYON
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'anasayfa.dart';
import 'news_page.dart';           // ✅ YENİ EKLEME
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
    const Anasayfa(),        // 0 - Ana Sayfa
    const NewsPage(),        // 1 - Haberler ✅ YENİ EKLEME
    const KadroSayfasi(),    // 2 - Kadro
    const TakvimSayfasi(),   // 3 - Fikstür
    const ForumSayfasi(),    // 4 - Forum
    const GaleriSayfasi(),   // 5 - Galeri
    const ProfilePage(),     // 6 - Profil
  ];

  // ✅ NAVIGASYON İTEMLERİ (6 ADET)
  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Ana Sayfa',
    ),
    _NavItem(                              // ✅ YENİ EKLEME
      icon: Icons.article_outlined,
      activeIcon: Icons.article,
      label: 'Haberler',
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
    _pageController = PageController(initialPage: 0);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Provider'ı dinle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tabProvider = Provider.of<TabProvider>(context, listen: false);
      tabProvider.addListener(_onTabChanged);
    });
  }

  void _onTabChanged() {
    final tabProvider = Provider.of<TabProvider>(context, listen: false);
    final newIndex = tabProvider.currentIndex;

    if (newIndex != _currentIndex && newIndex < _pages.length) {
      setState(() {
        _currentIndex = newIndex;
      });
      _pageController.animateToPage(
        newIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.lightImpact();
    final tabProvider = Provider.of<TabProvider>(context, listen: false);
    tabProvider.changeTab(index);  // ✅ BU DOĞRU
  }

  void _onPageChanged(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
      final tabProvider = Provider.of<TabProvider>(context, listen: false);
      tabProvider.setCurrentIndex(index);  // ✅ BU DOĞRU
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TabProvider>(
      builder: (context, tabProvider, child) {
        return Scaffold(
          body: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: _pages,
          ),
          bottomNavigationBar: _buildBottomNavBar(),
        );
      },
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(
            color: Colors.green.shade700,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: 65,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_navItems.length, (index) {
              final item = _navItems[index];
              final isSelected = _currentIndex == index;

              return GestureDetector(
                onTap: () => _onItemTapped(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.green.shade700.withOpacity(0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: Colors.green.shade700, width: 1)
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected
                            ? Colors.green.shade400
                            : Colors.grey.shade500,
                        size: 22,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.green.shade400
                              : Colors.grey.shade500,
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// Navigasyon öğesi sınıfı
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