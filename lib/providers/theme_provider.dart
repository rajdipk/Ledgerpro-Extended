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
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
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
  static const Color errorLight = Color(0xFFE74C3C);
  static const Color successLight = Color(0xFF2ECC71);
  static const Color warningLight = Color(0xFFF1C40F);
  static const Color outlineLight = Color(0xFFE0E0E0);

  // Dark theme colors
  static const Color primaryDark = Color(0xFF1A1A2E);
  static const Color accentDark = Color(0xFF3498DB);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color textDark = Colors.white;
  static const Color errorDark = Color(0xFFE74C3C);
  static const Color successDark = Color(0xFF2ECC71);
  static const Color warningDark = Color(0xFFF1C40F);
  static const Color outlineDark = Color(0xFF424242);

  ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: primaryLight,
        scaffoldBackgroundColor: backgroundLight,
        colorScheme: const ColorScheme.light(
          primary: Colors.teal,
          secondary: Colors.orangeAccent,
          surface: surfaceLight,
          background: backgroundLight,
          error: errorLight,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: textLight,
          onBackground: textLight,
          onError: Colors.white,
          outline: outlineLight,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: textLight,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          color: surfaceLight,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: outlineLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: outlineLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primaryLight, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: errorLight),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        textTheme: const TextTheme(
          displayLarge:
              TextStyle(color: textLight, fontWeight: FontWeight.bold),
          displayMedium:
              TextStyle(color: textLight, fontWeight: FontWeight.bold),
          displaySmall:
              TextStyle(color: textLight, fontWeight: FontWeight.bold),
          headlineLarge:
              TextStyle(color: textLight, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: textLight),
          headlineSmall: TextStyle(color: textLight),
          titleLarge: TextStyle(color: textLight, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: textLight),
          titleSmall: TextStyle(color: textLight),
          bodyLarge: TextStyle(color: textLight),
          bodyMedium: TextStyle(color: textLight),
          bodySmall: TextStyle(color: textLight),
        ),
        iconTheme: const IconThemeData(color: primaryLight),
        dividerTheme: const DividerThemeData(
          color: outlineLight,
          thickness: 1,
          space: 24,
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
          background: backgroundDark,
          error: errorDark,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: textDark,
          onBackground: textDark,
          onError: Colors.white,
          outline: outlineDark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: textDark,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          color: surfaceDark,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surfaceDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: outlineDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: outlineDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: accentDark, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: errorDark),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: textDark, fontWeight: FontWeight.bold),
          displayMedium:
              TextStyle(color: textDark, fontWeight: FontWeight.bold),
          displaySmall: TextStyle(color: textDark, fontWeight: FontWeight.bold),
          headlineLarge:
              TextStyle(color: textDark, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: textDark),
          headlineSmall: TextStyle(color: textDark),
          titleLarge: TextStyle(color: textDark, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: textDark),
          titleSmall: TextStyle(color: textDark),
          bodyLarge: TextStyle(color: textDark),
          bodyMedium: TextStyle(color: textDark),
          bodySmall: TextStyle(color: textDark),
        ),
        iconTheme: const IconThemeData(color: accentDark),
        dividerTheme: const DividerThemeData(
          color: outlineDark,
          thickness: 1,
          space: 24,
        ),
      );
}
