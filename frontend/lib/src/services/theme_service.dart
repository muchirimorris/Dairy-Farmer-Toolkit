import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeService extends ChangeNotifier {
  static const String _boxName = 'settings';
  static const String _key = 'themeMode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  ThemeService() {
    _loadTheme();
  }

  void _loadTheme() {
    try {
      final box = Hive.box(_boxName);
      final isDark = box.get(_key) as bool?;
      if (isDark != null) {
        _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      }
    } catch (e) {
      debugPrint("Error loading theme: $e");
    }
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();

    try {
      final box = Hive.box(_boxName);
      await box.put(_key, _themeMode == ThemeMode.dark);
    } catch (e) {
      debugPrint("Error saving theme: $e");
    }
  }

  Future<void> setDarkTheme(bool isDark) async {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();

    try {
      final box = Hive.box(_boxName);
      await box.put(_key, isDark);
    } catch (e) {
      debugPrint("Error saving theme: $e");
    }
  }
}
