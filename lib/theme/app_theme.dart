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
      Color(0xFF4A4A68); // Slightly lighter secondary text

  // Enhanced dark theme colors
  static const Color _darkPrimaryColor = Color(0xFF5B74FF); // Brighter blue
  static const Color _darkAccentColor = Color(0xFF7B8FFF); // Lighter accent
  static const Color _darkBackgroundColor = Color(0xFF121220); // Deeper dark
  static const Color _darkSurfaceColor = Color(0xFF1E1E2E); // Richer surface
  static const Color _darkErrorColor = Color(0xFFFF6B7A); // Brighter error
  static const Color _darkTextPrimaryColor =
      Color(0xFFF5F5FA); // Crisp white text
  static const Color _darkTextSecondaryColor =
      Color(0xFFB8B8D0); // Softer secondary text

  // Additional dark theme colors
  static const Color _darkCardColor =
      Color(0xFF252538); // Slightly lighter than surface
  static const Color _darkDividerColor = Color(0xFF2A2A40); // Subtle divider
  static const Color _darkDisabledColor =
      Color(0xFF4A4A68); // Muted disabled state
  static const Color _darkSuccessColor = Color(0xFF4CAF50); // Success green
  static const Color _darkWarningColor = Color(0xFFFFC107); // Warning amber
  static const Color _darkInfoColor = Color(0xFF2196F3); // Info blue

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
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: _darkTextPrimaryColor),
    displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: _darkTextPrimaryColor),
    displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: _darkTextPrimaryColor),
    headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _darkTextPrimaryColor),
    headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _darkTextPrimaryColor),
    titleLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: _darkTextPrimaryColor),
    bodyLarge: TextStyle(fontSize: 16, color: _darkTextPrimaryColor),
    bodyMedium: TextStyle(fontSize: 14, color: _darkTextPrimaryColor),
    bodySmall: TextStyle(fontSize: 12, color: _darkTextSecondaryColor),
    labelLarge: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w500, color: _darkPrimaryColor),
  );

  // Light theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: _lightPrimaryColor,
    scaffoldBackgroundColor: _lightBackgroundColor,
    colorScheme: const ColorScheme.light(
      primary: _lightPrimaryColor,
      secondary: _lightAccentColor,
      surface: _lightSurfaceColor,
      error: _lightErrorColor,
    ),
    textTheme: _lightTextTheme,
    appBarTheme: AppBarTheme(
      elevation: 1, // Slight elevation for depth
      backgroundColor: _lightBackgroundColor,
      iconTheme: const IconThemeData(color: _lightTextPrimaryColor),
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
        borderSide: const BorderSide(color: _lightPrimaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _lightErrorColor),
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
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _darkTextPrimaryColor,
      onError: Colors.white,
      brightness: Brightness.dark,
    ),
    textTheme: _darkTextTheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      backgroundColor: _darkBackgroundColor,
      iconTheme: const IconThemeData(color: _darkTextPrimaryColor),
      titleTextStyle: _darkTextTheme.titleLarge,
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    cardTheme: CardTheme(
      color: _darkCardColor,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkSurfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _darkDividerColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _darkDividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _darkPrimaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _darkErrorColor),
      ),
      contentPadding: const EdgeInsets.all(20),
      hintStyle: TextStyle(color: _darkTextSecondaryColor.withOpacity(0.7)),
      labelStyle: const TextStyle(color: _darkTextSecondaryColor),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkPrimaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 4,
        shadowColor: _darkPrimaryColor.withOpacity(0.5),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _darkPrimaryColor,
        side: BorderSide(color: _darkPrimaryColor.withOpacity(0.7), width: 1.5),
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
      backgroundColor: _darkCardColor,
      selectedItemColor: _darkPrimaryColor,
      unselectedItemColor: _darkTextSecondaryColor,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),
    dividerTheme: const DividerThemeData(
      color: _darkDividerColor,
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: _darkCardColor,
      contentTextStyle: const TextStyle(color: _darkTextPrimaryColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      actionTextColor: _darkPrimaryColor,
    ),
    dialogTheme: DialogTheme(
      backgroundColor: _darkCardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: _darkTextTheme.titleLarge,
      contentTextStyle: _darkTextTheme.bodyMedium,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _darkPrimaryColor,
      foregroundColor: Colors.white,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return _darkPrimaryColor;
        }
        return _darkDisabledColor;
      }),
      trackColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return _darkPrimaryColor.withOpacity(0.5);
        }
        return _darkDisabledColor.withOpacity(0.3);
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return _darkPrimaryColor;
        }
        return _darkDisabledColor;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return _darkPrimaryColor;
        }
        return _darkDisabledColor;
      }),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _darkPrimaryColor,
      circularTrackColor: _darkDividerColor,
      linearTrackColor: _darkDividerColor,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: _darkSurfaceColor,
      disabledColor: _darkDisabledColor.withOpacity(0.2),
      selectedColor: _darkPrimaryColor.withOpacity(0.2),
      secondarySelectedColor: _darkPrimaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: _darkTextTheme.bodySmall,
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: _darkCardColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: _darkTextPrimaryColor),
    ),
  );
}
