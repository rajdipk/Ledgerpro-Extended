import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themePreferenceKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.light;

  ThemeProvider() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeMode = prefs.getString(_themePreferenceKey);
    if (savedThemeMode != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == savedThemeMode,
        orElse: () => ThemeMode.light,
      );
      notifyListeners();
    }
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themePreferenceKey, _themeMode.toString());
    notifyListeners();
  }

  // Light theme colors
  static const Color primaryLight = Color(0xFF2C3E50);
  static const Color accentLight = Color(0xFF3498DB);
  static const Color backgroundLight = Color(0xFFF5F6FA);
  static const Color surfaceLight = Colors.white;
  static const Color textLight = Color(0xFF2C3E50);

  // Dark theme colors
  static const Color primaryDark = Color(0xFF1A1A2E);
  static const Color accentDark = Color(0xFF3498DB);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textDark = Colors.white;

  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: primaryLight,
        scaffoldBackgroundColor: backgroundLight,
        colorScheme: const ColorScheme.light(
          primary: primaryLight,
          secondary: accentLight,
          surface: surfaceLight,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: textLight,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: surfaceLight,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: textLight),
          titleMedium: TextStyle(color: textLight),
          bodyLarge: TextStyle(color: textLight),
          bodyMedium: TextStyle(color: textLight),
        ),
      );

  ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: primaryDark,
        scaffoldBackgroundColor: backgroundDark,
        colorScheme: const ColorScheme.dark(
          primary: primaryDark,
          secondary: accentDark,
          surface: surfaceDark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: textDark,
          elevation: 0,
        ),
        cardTheme: CardTheme(
          color: surfaceDark,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(color: textDark),
          titleMedium: TextStyle(color: textDark),
          bodyLarge: TextStyle(color: textDark),
          bodyMedium: TextStyle(color: textDark),
        ),
      );
}
