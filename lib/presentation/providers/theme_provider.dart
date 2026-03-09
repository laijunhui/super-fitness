import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// 主题状态管理
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  AppThemeMode _appThemeMode = AppThemeMode.light;
  late SharedPreferences _prefs;
  bool _initialized = false;

  ThemeProvider() {
    _init();
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadThemeMode();
    _initialized = true;
  }

  ThemeMode get themeMode => _themeMode;
  AppThemeMode get appThemeMode => _appThemeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isGreenMode => _appThemeMode == AppThemeMode.green;
  bool get isInitialized => _initialized;

  /// 加载保存的主题模式
  void _loadThemeMode() {
    final mode = _prefs.getString('theme_mode');
    if (mode != null) {
      _appThemeMode = AppThemeMode.values.firstWhere(
        (e) => e.name == mode,
        orElse: () => AppThemeMode.light,
      );
      _updateThemeMode();
    }
  }

  /// 根据 appThemeMode 更新 themeMode
  void _updateThemeMode() {
    switch (_appThemeMode) {
      case AppThemeMode.light:
        _themeMode = ThemeMode.light;
        break;
      case AppThemeMode.dark:
        _themeMode = ThemeMode.dark;
        break;
      case AppThemeMode.green:
        _themeMode = ThemeMode.light; // 绿植主题基于浅色
        break;
    }
  }

  /// 切换主题
  void toggleTheme() {
    if (_appThemeMode == AppThemeMode.light) {
      setThemeMode(AppThemeMode.dark);
    } else {
      setThemeMode(AppThemeMode.light);
    }
  }

  /// 设置主题模式
  void setThemeMode(AppThemeMode mode) {
    _appThemeMode = mode;
    _updateThemeMode();
    _prefs.setString('theme_mode', mode.name);
    notifyListeners();
  }

  /// 切换到浅色主题
  void setLightMode() {
    setThemeMode(AppThemeMode.light);
  }

  /// 切换到深色主题
  void setDarkMode() {
    setThemeMode(AppThemeMode.dark);
  }

  /// 切换到绿植主题
  void setGreenMode() {
    setThemeMode(AppThemeMode.green);
  }

  /// 获取当前主题的主色调
  Color get primaryColor {
    switch (_appThemeMode) {
      case AppThemeMode.light:
        return AppColors.lightPrimary;
      case AppThemeMode.dark:
        return AppColors.darkPrimary;
      case AppThemeMode.green:
        return AppColors.greenThemePrimary;
    }
  }

  /// 获取当前主题的背景色
  Color get backgroundColor {
    switch (_appThemeMode) {
      case AppThemeMode.light:
        return AppColors.lightBackground;
      case AppThemeMode.dark:
        return AppColors.darkBackground;
      case AppThemeMode.green:
        return AppColors.greenThemeBackground;
    }
  }

  /// 获取当前主题的卡片背景色
  Color get cardBackgroundColor {
    switch (_appThemeMode) {
      case AppThemeMode.light:
        return AppColors.lightCardBackground;
      case AppThemeMode.dark:
        return AppColors.darkCardBackground;
      case AppThemeMode.green:
        return AppColors.greenThemeCardBackground;
    }
  }

  /// 获取当前主题的主要文字颜色
  Color get textPrimaryColor {
    switch (_appThemeMode) {
      case AppThemeMode.light:
        return AppColors.lightTextPrimary;
      case AppThemeMode.dark:
        return AppColors.darkTextPrimary;
      case AppThemeMode.green:
        return AppColors.greenThemeTextPrimary;
    }
  }

  /// 获取当前主题的次要文字颜色
  Color get textSecondaryColor {
    switch (_appThemeMode) {
      case AppThemeMode.light:
        return AppColors.lightTextSecondary;
      case AppThemeMode.dark:
        return AppColors.darkTextSecondary;
      case AppThemeMode.green:
        return AppColors.greenThemeTextSecondary;
    }
  }

  /// 获取当前主题的阴影亮部颜色
  Color get shadowLightColor {
    switch (_appThemeMode) {
      case AppThemeMode.light:
        return AppColors.lightShadowLight;
      case AppThemeMode.dark:
        return AppColors.darkShadowLight;
      case AppThemeMode.green:
        return AppColors.greenThemeShadowLight;
    }
  }

  /// 获取当前主题的阴影暗部颜色
  Color get shadowDarkColor {
    switch (_appThemeMode) {
      case AppThemeMode.light:
        return AppColors.lightShadowDark;
      case AppThemeMode.dark:
        return AppColors.darkShadowDark;
      case AppThemeMode.green:
        return AppColors.greenThemeShadowDark;
    }
  }
}
