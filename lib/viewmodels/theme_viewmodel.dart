import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ThemeViewModel extends ChangeNotifier {
  bool _isDarkMode = SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  bool get isDarkMode => _isDarkMode;

  ThemeViewModel() {
    // Écouter les changements de thème système
    SchedulerBinding.instance.platformDispatcher.onPlatformBrightnessChanged = () {
      _isDarkMode = SchedulerBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
      notifyListeners();
    };
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  @override
  void dispose() {
    SchedulerBinding.instance.platformDispatcher.onPlatformBrightnessChanged = null;
    super.dispose();
  }
}
