import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Color constants
  static const Color _lightPrimaryColor = Color(0xFF3D56F0);
  static const Color _lightAccentColor = Color(0xFF4F67FF);
  static const Color _lightBackgroundColor =
      Color(0xFFF5F7FA); // Softer background
  static const Color _lightSurfaceColor = Colors.white;
  static const Color _lightErrorColor = Color(0xFFB00020);
  static const Color _lightTextPrimaryColor =
      Color(0xFF1A1A2E); // Darker text color
  static const Color _lightTextSecondaryColor =
      Color(0xFF4A4A68); // Slightly lighter secondary te

  static const Color _darkPrimaryColor = Color(0xFF4F67FF);
  static const Color _darkAccentColor = Color(0xFF6B7FFF);
  static const Color _darkBackgroundColor = Color(0xFF1A1A2E);
  static const Color _darkSurfaceColor = Color(0xFF252543);
  static const Color _darkErrorColor = Color(0xFFCF6679);

  // Text themes
  static const TextTheme _lightTextTheme = TextTheme(
    displayLarge: TextStyle(
        fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
    displayMedium: TextStyle(
        fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
    displaySmall: TextStyle(
        fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
    headlineMedium: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w600, color: Colors.black87),
    headlineSmall: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
    titleLarge: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
    bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
    bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
    bodySmall: TextStyle(fontSize: 12, color: Colors.black54),
    labelLarge: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w500, color: _lightPrimaryColor),
  );

  static const TextTheme _darkTextTheme = TextTheme(
    displayLarge: TextStyle(
        fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
    displayMedium: TextStyle(
        fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
    displaySmall: TextStyle(
        fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
    headlineMedium: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
    headlineSmall: TextStyle(
        fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
    titleLarge: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
    bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
    bodyMedium: TextStyle(fontSize: 14, color: Colors.white),
    bodySmall: TextStyle(fontSize: 12, color: Colors.white70),
    labelLarge: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w500, color: _darkPrimaryColor),
  );

  // Light theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: _lightPrimaryColor,
    scaffoldBackgroundColor: _lightBackgroundColor,
    colorScheme: ColorScheme.light(
      primary: _lightPrimaryColor,
      secondary: _lightAccentColor,
      surface: _lightSurfaceColor,
      error: _lightErrorColor,
      background: _lightBackgroundColor,
    ),
    textTheme: _lightTextTheme,
    appBarTheme: AppBarTheme(
      elevation: 1, // Slight elevation for depth
      backgroundColor: _lightBackgroundColor,
      iconTheme: IconThemeData(color: _lightTextPrimaryColor),
      titleTextStyle: _lightTextTheme.titleLarge,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
    ),
    cardTheme: CardTheme(
      color: _lightSurfaceColor,
      elevation: 3, // Increased elevation
      shadowColor: Colors.black.withOpacity(0.1), // Soft shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            BorderSide(color: Colors.grey.shade200, width: 1), // Subtle border
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white, // Pure white for input backgrounds
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _lightPrimaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _lightErrorColor),
      ),
      contentPadding: const EdgeInsets.all(20),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightPrimaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 3, // Slight elevation
        shadowColor: _lightPrimaryColor.withOpacity(0.4), // Soft shadow
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _lightPrimaryColor,
        side: BorderSide(color: _lightPrimaryColor.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _lightPrimaryColor,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: _lightSurfaceColor,
      selectedItemColor: _lightPrimaryColor,
      unselectedItemColor: _lightTextSecondaryColor.withOpacity(0.6),
      elevation: 4, // Slight elevation
      type: BottomNavigationBarType.fixed,
    ),
    dividerTheme: DividerThemeData(
      color: Colors.grey.shade300,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: _lightTextPrimaryColor,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );

  // Dark theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: _darkPrimaryColor,
    scaffoldBackgroundColor: _darkBackgroundColor,
    colorScheme: const ColorScheme.dark(
      primary: _darkPrimaryColor,
      secondary: _darkAccentColor,
      surface: _darkSurfaceColor,
      error: _darkErrorColor,
    ),
    textTheme: _darkTextTheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: _darkBackgroundColor,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: _darkTextTheme.titleLarge,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    cardTheme: CardTheme(
      color: _darkSurfaceColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkSurfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _darkPrimaryColor),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _darkErrorColor),
      ),
      contentPadding: const EdgeInsets.all(20),
      hintStyle: const TextStyle(color: Colors.white38),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkPrimaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 2,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _darkPrimaryColor,
        side: const BorderSide(color: _darkPrimaryColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _darkPrimaryColor,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _darkSurfaceColor,
      selectedItemColor: _darkPrimaryColor,
      unselectedItemColor: Colors.white70,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    dividerTheme: const DividerThemeData(
      color: Colors.white24,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: _darkSurfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
