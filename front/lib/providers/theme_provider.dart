import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:front/utils/app_colors.dart';
import 'package:front/utils/app_theme.dart';
import 'package:front/utils/hive_utils.dart';

class ThemeProvider extends ChangeNotifier with WidgetsBindingObserver {
  ThemeMode _mode = ThemeMode.system;

  ThemeProvider() {
    WidgetsBinding.instance.addObserver(this);
    final saved = HiveUtils.getData('themeMode');
    if (saved == 'dark') {
      _mode = ThemeMode.dark;
    } else if (saved == 'light') {
      _mode = ThemeMode.light;
    } else {
      _mode = ThemeMode.system;
    }
    _applyThemeColors();
  }

  ThemeMode get mode => _mode;

  ThemeData get lightTheme => AppTheme.lightTheme;
  ThemeData get darkTheme => AppTheme.darkTheme;

  Future<void> toggle() async {
    if (_mode == ThemeMode.dark) {
      _mode = ThemeMode.light;
      await HiveUtils.putData('themeMode', 'light');
    } else {
      _mode = ThemeMode.dark;
      await HiveUtils.putData('themeMode', 'dark');
    }
    _applyThemeColors();
    notifyListeners();
  }

  void setSystemMode() {
    _mode = ThemeMode.system;
    HiveUtils.putData('themeMode', 'system');
    _applyThemeColors();
    notifyListeners();
  }

  void _applyThemeColors() {
    final bool isDark = _mode == ThemeMode.dark ||
        (_mode == ThemeMode.system &&
            SchedulerBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark);
    AppColors.applyTheme(isDark);
  }

  @override
  void didChangePlatformBrightness() {
    if (_mode == ThemeMode.system) {
      _applyThemeColors();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}


