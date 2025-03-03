import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  final String key = "theme";
  late SharedPreferences _prefs;
  bool _isDarkMode = false; // Default value
  bool get isDarkMode => _isDarkMode;

  ThemeProvider();

  // Called when the provider is initialized
  Future<void> _loadFromPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool(key) ?? false;
    notifyListeners();
  }

  // Save the theme mode to shared preferences
  Future<void> _saveToPrefs() async {
    await _prefs.setBool(key, _isDarkMode);
  }

  // Toggle between light and dark theme
  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    await _saveToPrefs();
    notifyListeners();
  }

  // Set specific theme mode
  void setDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    await _saveToPrefs();
    notifyListeners();
  }

  // Ensure preferences are loaded before using the provider
  Future<void> initialize() async {
    await _loadFromPrefs();
  }
}
