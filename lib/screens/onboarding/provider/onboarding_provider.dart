import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingProvider extends ChangeNotifier {
  int _currentPage = 0;
  final int totalPages = 4;
  bool _isDemoMode = false;
  bool _hasCompletedOnboarding = false;
  bool _isInitialized = false;

  int get currentPage => _currentPage;
  bool get isDemoMode => _isDemoMode;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get isInitialized => _isInitialized;

  // Initialize provider and check if onboarding was completed
  Future<void> initialize() async {
    if (_isInitialized) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    _hasCompletedOnboarding =
        prefs.getBool('has_completed_onboarding') ?? false;
    _isDemoMode = prefs.getBool('is_demo_mode') ?? false;
    _isInitialized = true;
    notifyListeners();
  }

  void setPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  bool get isLastPage => _currentPage == totalPages - 1;

  Future<void> completeOnboarding({bool demoMode = false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);
    _hasCompletedOnboarding = true;
    _isDemoMode = demoMode;
    await prefs.setBool('is_demo_mode', demoMode);
    notifyListeners();
  }

  Future<void> initializeDemoMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDemoMode = prefs.getBool('is_demo_mode') ?? false;
    notifyListeners();
  }

  Future<void> exitDemoMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_demo_mode', false);
    _isDemoMode = false;
    notifyListeners();
  }
}
