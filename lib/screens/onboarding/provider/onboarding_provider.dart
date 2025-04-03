import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingProvider extends ChangeNotifier {
  static const String _hasCompletedOnboardingKey =
      'first_time_onboarding_completed';
  static const String _isDemoModeKey = 'is_demo_mode';

  int _currentPage = 0;
  final int totalPages = 4;
  bool _isDemoMode = false;
  bool _hasCompletedOnboarding = false;

  OnboardingProvider() {
    _loadOnboardingState();
  }

  // Getters
  int get currentPage => _currentPage;
  bool get isDemoMode => _isDemoMode;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;
  bool get isLastPage => _currentPage == totalPages - 1;

  // Load saved state
  Future<void> _loadOnboardingState() async {
    final prefs = await SharedPreferences.getInstance();
    _hasCompletedOnboarding =
        prefs.getBool(_hasCompletedOnboardingKey) ?? false;
    _isDemoMode = prefs.getBool(_isDemoModeKey) ?? false;
    notifyListeners();
  }

  void setPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  Future<void> completeOnboarding({bool demoMode = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasCompletedOnboardingKey, true);
    _hasCompletedOnboarding = true;
    _isDemoMode = demoMode;
    await prefs.setBool(_isDemoModeKey, demoMode);
    notifyListeners();
  }

  Future<void> initializeDemoMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isDemoMode = prefs.getBool(_isDemoModeKey) ?? false;
    notifyListeners();
  }

  Future<void> exitDemoMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isDemoModeKey, false);
    _isDemoMode = false;
    notifyListeners();
  }

  Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasCompletedOnboardingKey, false);
    await prefs.setBool(_isDemoModeKey, false);
    _hasCompletedOnboarding = false;
    _isDemoMode = false;
    notifyListeners();
  }
}
