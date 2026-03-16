import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../models/user_model.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/register_usecase.dart';

class AuthNotifier extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final _storage = const FlutterSecureStorage();

  AuthNotifier({
    required this.loginUseCase,
    required this.registerUseCase,
  });

  User? _user;
  User? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userJson = await _storage.read(key: 'user_session');
      if (userJson != null) {
        final userData = jsonDecode(userJson);
        _user = User(
          id: userData['id'],
          name: userData['name'],
          email: userData['email'],
          role: UserRole.values.firstWhere(
            (e) => e.name == userData['role'],
            orElse: () => UserRole.student,
          ),
        );
      }
    } catch (e) {
      await _storage.delete(key: 'user_session');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userEntity = await loginUseCase(email, password);
      _user = User(
        id: '1', // Placeholder
        name: userEntity.name,
        email: userEntity.email,
        role: UserRole.values.firstWhere(
          (e) => e.name == userEntity.role,
          orElse: () => UserRole.student,
        ),
      );

      // Save session
      final userData = {
        'id': _user!.id,
        'name': _user!.name,
        'email': _user!.email,
        'role': _user!.role.name,
      };
      await _storage.write(key: 'user_session', value: jsonEncode(userData));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString().contains('Exception: ') 
          ? e.toString().split('Exception: ')[1] 
          : 'Login failed';
      notifyListeners();
    }
  }

  Future<bool> register({
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
      final success = await registerUseCase(
        name: name,
        email: email,
        password: password,
        role: role,
        schoolId: schoolId,
        phone: phone,
      );
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString().contains('Exception: ') 
          ? e.toString().split('Exception: ')[1] 
          : 'Registration failed';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    await _storage.delete(key: 'user_session');
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
