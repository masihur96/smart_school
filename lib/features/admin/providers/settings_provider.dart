import 'package:flutter/material.dart';
import 'package:smart_school/core/utils/storage_service.dart';
import 'package:smart_school/services/notification_service.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');
  bool _isHomeworkNotifyEnabled = true;
  bool _isAttendanceNotifyEnabled = true;

  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  bool get isHomeworkNotifyEnabled => _isHomeworkNotifyEnabled;
  bool get isAttendanceNotifyEnabled => _isAttendanceNotifyEnabled;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final theme = await StorageService.getTheme();
    if (theme != null) {
      if (theme == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (theme == 'light') {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.system;
      }
    }

    final localeCode = await StorageService.getLocale();
    if (localeCode != null) {
      _locale = Locale(localeCode);
    }

    _isHomeworkNotifyEnabled = await StorageService.getHomeworkNotify();
    _isAttendanceNotifyEnabled = await StorageService.getAttendanceNotify();

    // Ensure topics are in sync upon app start
    _syncTopics();
    
    notifyListeners();
  }

  void _syncTopics() {
    final ns = NotificationService();
    if (_isHomeworkNotifyEnabled) {
      ns.subscribeToTopic('homework');
    } else {
      ns.unsubscribeFromTopic('homework');
    }

    if (_isAttendanceNotifyEnabled) {
      ns.subscribeToTopic('attendance');
    } else {
      ns.unsubscribeFromTopic('attendance');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    String themeValue;
    switch (mode) {
      case ThemeMode.dark:
        themeValue = 'dark';
        break;
      case ThemeMode.light:
        themeValue = 'light';
        break;
      case ThemeMode.system:
        themeValue = 'system';
        break;
    }
    await StorageService.saveTheme(themeValue);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    await StorageService.saveLocale(locale.languageCode);
    notifyListeners();
  }

  Future<void> setHomeworkNotify(bool value) async {
    _isHomeworkNotifyEnabled = value;
    await StorageService.saveHomeworkNotify(value);
    if (value) {
      await NotificationService().subscribeToTopic('homework');
    } else {
      await NotificationService().unsubscribeFromTopic('homework');
    }
    notifyListeners();
  }

  Future<void> setAttendanceNotify(bool value) async {
    _isAttendanceNotifyEnabled = value;
    await StorageService.saveAttendanceNotify(value);
    if (value) {
      await NotificationService().subscribeToTopic('attendance');
    } else {
      await NotificationService().unsubscribeFromTopic('attendance');
    }
    notifyListeners();
  }
}
