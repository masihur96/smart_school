import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../models/user_model.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/register_usecase.dart';
import '../domain/usecases/get_profile_usecase.dart';

class AuthNotifier extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final GetProfileUseCase getProfileUseCase;
  final _storage = const FlutterSecureStorage();

  AuthNotifier({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.getProfileUseCase,
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
        _user = User.fromJson(userData);
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
      await loginUseCase(email, password);
      
      // Fetch full profile after login
      final profile = await getProfileUseCase();
      
      _user = User(
        id: profile.id,
        name: profile.name,
        email: profile.email,
        role: UserRole.values.firstWhere(
          (e) => e.name == profile.role,
          orElse: () => UserRole.student,
        ),
        schoolId: profile.schoolId,
        phone: profile.phone,
      );

      // Save session
      await _storage.write(key: 'user_session', value: jsonEncode(_user!.toJson()));

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
// ... lines omitted for brevity ...
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
