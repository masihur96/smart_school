import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _tempTokenKey = 'temp_token';
  static const String _forceResetKey = 'force_reset';
  static const String _userEmailKey = 'user_email';
  static const String _userPasswordKey = 'user_password';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveSmallToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tempTokenKey, token);
  }

  static Future<String?> getSmallToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tempTokenKey);
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

  static Future<void> clearCredential() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userPasswordKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
