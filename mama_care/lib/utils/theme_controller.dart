// utils/theme_controller.dart

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:mama_care/data/local/database_helper.dart';

@injectable
class ThemeController extends ChangeNotifier {
  final DatabaseHelper _databaseHelper;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeController(this._databaseHelper) {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;

  // Load saved theme preference from database
  Future<void> _loadTheme() async {
    final theme = await _databaseHelper.getPreference('theme');
    if (theme != null) {
      setThemeMode(theme);
    }
  }

  // Set and save theme preference
  Future<void> setThemeMode(String theme) async {
    switch (theme) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      case 'system':
      default:
        _themeMode = ThemeMode.system;
        break;
    }
    
    await _databaseHelper.setPreference('theme', theme);
    notifyListeners();
  }

  // Check if dark mode is active
  bool isDarkMode(BuildContext context) {
    if (_themeMode == ThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }
}