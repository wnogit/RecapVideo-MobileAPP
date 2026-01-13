import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme Mode State
enum AppThemeMode { system, light, dark }

/// Theme Provider
class ThemeNotifier extends StateNotifier<AppThemeMode> {
  static const _key = 'app_theme_mode';

  ThemeNotifier() : super(AppThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value != null) {
      state = AppThemeMode.values.firstWhere(
        (e) => e.name == value,
        orElse: () => AppThemeMode.system,
      );
    }
  }

  Future<void> setTheme(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  ThemeMode get themeMode {
    switch (state) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

/// Theme Provider
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier();
});

/// Light Theme
final lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF8B5CF6),
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: const Color(0xFFF8F9FA),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: Colors.black87,
    elevation: 0,
  ),
  cardTheme: CardTheme(
    color: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.grey.shade100,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  ),
);

/// Dark Theme
final darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF8B5CF6),
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: const Color(0xFF0A0A0A),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0A0A0A),
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardTheme: CardTheme(
    color: const Color(0xFF1a1a2e),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFF1a1a2e),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  ),
);
