import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  final String key = "theme";
  SharedPreferences? _prefs;
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;
  bool _isInitialized = false;

  ThemeProvider();

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (!_isInitialized) {
      _prefs = await SharedPreferences.getInstance();
      _isDarkMode = _prefs?.getBool(key) ?? false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _loadFromPrefs() async {
    if (_prefs != null) {
      _isDarkMode = _prefs!.getBool(key) ?? false;
      notifyListeners();
    }
  }

  // Save the theme mode to shared preferences
  Future<void> _saveToPrefs() async {
    if (_prefs != null) {
      await _prefs!.setBool(key, _isDarkMode);
    }
  }

  // Toggle between light and dark theme
  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _saveToPrefs();
    notifyListeners();
  }

  void setDarkMode(bool isDark) async {
    if (_isDarkMode != isDark) {
      _isDarkMode = isDark;
      await _saveToPrefs();
      notifyListeners();
    }
  }

  void forceThemeUpdate() {
    notifyListeners();
  }
}
