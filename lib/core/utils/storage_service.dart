import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _tempTokenKey = 'temp_token';
  static const String _forceResetKey = 'force_reset';
  static const String _userEmailKey = 'user_email';
  static const String _userPasswordKey = 'user_password';
  static const String _themeKey = 'app_theme';
  static const String _localeKey = 'app_locale';
  static const String _homeworkNotifyKey = 'homework_notify';
  static const String _attendanceNotifyKey = 'attendance_notify';

  static const _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  static Future<void> saveSmallToken(String token) async {
    await _storage.write(key: _tempTokenKey, value: token);
  }

  static Future<String?> getSmallToken() async {
    return await _storage.read(key: _tempTokenKey);
  }

  static Future<void> saveIsForcePasswordReset(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_forceResetKey, value);
  }

  static Future<bool?> getIsForcePasswordReset() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_forceResetKey);
  }

  static Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  static Future<void> savePassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userPasswordKey, password);
  }

  static Future<String?> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userPasswordKey);
  }

  static Future<void> saveTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme);
  }

  static Future<String?> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey);
  }

  static Future<void> saveLocale(String locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale);
  }

  static Future<String?> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey);
  }

  static Future<void> saveHomeworkNotify(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_homeworkNotifyKey, value);
  }

  static Future<bool> getHomeworkNotify() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_homeworkNotifyKey) ?? true;
  }

  static Future<void> saveAttendanceNotify(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_attendanceNotifyKey, value);
  }

  static Future<bool> getAttendanceNotify() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_attendanceNotifyKey) ?? true;
  }

  static Future<void> clearCredential() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userPasswordKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _storage.deleteAll();
  }
}
