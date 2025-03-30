import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

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
    _currentIndex = 2;
    notifyListeners();
  }

  // New methods for named route navigation
  void navigateToWallet(BuildContext context) {
    setWalletScreen();
  }

  void navigateToNetwork(BuildContext context) {
    setIndex(0);
  }

  void navigateToExplore(BuildContext context) {
    setIndex(1);
  }

  void navigateToInsights(BuildContext context) {
    setIndex(3);
  }

  void navigateToSettings(BuildContext context) {
    setIndex(4);
  }
}
