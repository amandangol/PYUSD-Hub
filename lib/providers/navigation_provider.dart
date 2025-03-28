import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 2; // Default to wallet screen (index 2)
  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  void resetToHome() {
    if (_currentIndex != 0) {
      _currentIndex = 0;
      notifyListeners();
    }
  }

  void setWalletScreen() {
    _currentIndex = 2; // Set to wallet screen
    notifyListeners();
  }
}
