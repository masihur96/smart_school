import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';

class AuthNotifier extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.login(email, password);
      if (user != null) {
        _user = user;
        _isLoading = false;
      } else {
        _isLoading = false;
        _error = 'Login failed';
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Network error or invalid credentials';
    }
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String schoolId,
    required String phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _authService.register(
        name: name,
        email: email,
        password: password,
        role: role,
        schoolId: schoolId,
        phone: phone,
      );

      if (user != null) {
        _user = user;
        _isLoading = false;
      } else {
        _isLoading = false;
        _error = 'Registration failed';
      }
    } catch (e) {
      String errorMessage = 'Registration failed';
      if (e is DioException) {
        errorMessage = e.response?.data?['message'] ?? 'Network error';
      }
      _isLoading = false;
      _error = errorMessage;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
