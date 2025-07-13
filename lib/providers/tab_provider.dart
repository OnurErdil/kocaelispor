// lib/providers/tab_provider.dart
import 'package:flutter/material.dart';

class TabProvider extends ChangeNotifier {
  int _currentIndex = 0;
  PageController? _pageController;

  int get currentIndex => _currentIndex;
  PageController? get pageController => _pageController;

  void setPageController(PageController controller) {
    _pageController = controller;
  }

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void changeTab(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      _pageController?.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      notifyListeners();
    }
  }
}