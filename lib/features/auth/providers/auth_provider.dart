import 'package:flutter/material.dart';
import '../../../models/user_model.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/register_usecase.dart';

class AuthNotifier extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;

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

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userEntity = await loginUseCase(email, password);
      // Mapping UserEntity to User model
      _user = User(
        id: '1', // Placeholder, ideally from entity/token
        name: userEntity.name,
        email: userEntity.email,
        role: UserRole.values.firstWhere(
          (e) => e.name == userEntity.role,
          orElse: () => UserRole.student,
        ),
      );
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
      if (success) {
        _error = null;
      }
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

  void logout() {
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
