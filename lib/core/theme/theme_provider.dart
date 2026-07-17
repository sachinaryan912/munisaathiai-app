import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const _key = 'muni_dark';
  ThemeMode mode = ThemeMode.light;

  Future<void> bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_key) ?? false;
    mode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  bool get isDark => mode == ThemeMode.dark;

  Future<void> toggle() async {
    mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, isDark);
  }
}
