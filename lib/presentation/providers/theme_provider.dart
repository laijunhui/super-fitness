import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// 主题状态管理
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// 切换主题
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  /// 设置主题
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  /// 切换到浅色主题
  void setLightMode() {
    _themeMode = ThemeMode.light;
    notifyListeners();
  }

  /// 切换到深色主题
  void setDarkMode() {
    _themeMode = ThemeMode.dark;
    notifyListeners();
  }
}
