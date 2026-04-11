import 'package:flutter/material.dart';
import 'package:smart_school/core/utils/storage_service.dart';
import 'dart:developer';
import '../../../models/user_model.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/register_usecase.dart';
import '../domain/usecases/get_profile_usecase.dart';
import '../domain/usecases/change_password_usecase.dart';
import '../../super_admin/models/subscription_model.dart';
import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';

class AuthNotifier extends ChangeNotifier {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final GetProfileUseCase getProfileUseCase;
  final ChangePasswordUseCase changePasswordUseCase;

  AuthNotifier({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.getProfileUseCase,
    required this.changePasswordUseCase,
  });

  User? _user;
  User? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Subscription? _adminSubscription;
  Subscription? get adminSubscription => _adminSubscription;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token != null) {
        // Fetch full profile by token
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
          classId: profile.classId,
          sectionId: profile.sectionId,
          phone: profile.phone,
          rollNumber: profile.rollNumber,
          designation: profile.designation,
          isActive: profile.isActive,
          createdAt: profile.createdAt != null
              ? DateTime.tryParse(profile.createdAt!)
              : null,
          lat: profile.lat,
          lon: profile.lon,
          radius: profile.radius,
        );

        if (_user?.role == UserRole.admin && _user?.schoolId != null) {
          await _fetchAdminSubscription(_user!.schoolId!);
        }
      } else {
        _user = null;
      }
    } catch (e) {
      log("Auth check error: $e");
      _user = null;
      await StorageService.clear();
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

      print("profile.classId:: ${profile.classId}");

      _user = User(
        id: profile.id,
        name: profile.name,
        email: profile.email,
        role: UserRole.values.firstWhere(
          (e) => e.name == profile.role,
          orElse: () => UserRole.student,
        ),
        schoolId: profile.schoolId,
        classId: profile.classId,
        sectionId: profile.sectionId,
        phone: profile.phone,
        rollNumber: profile.rollNumber,
        designation: profile.designation,
        isActive: profile.isActive,
        createdAt: profile.createdAt != null
            ? DateTime.tryParse(profile.createdAt!)
            : null,
        lat: profile.lat,
        lon: profile.lon,
        radius: profile.radius,
      );

      if (_user?.role == UserRole.admin && _user?.schoolId != null) {
        await _fetchAdminSubscription(_user!.schoolId!);
      }

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
    _adminSubscription = null;
    await StorageService.clear();
    notifyListeners();
  }

  Future<void> _fetchAdminSubscription(String schoolId) async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return;

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.schoolSubscription(schoolId),
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final dynamic rawData = response.data;
        final data = rawData is Map ? (rawData['data'] ?? rawData) : rawData;
        _adminSubscription = Subscription.fromJson(data);
        log('Fetched admin subscription for school: $schoolId (Active: ${_adminSubscription?.isActive})');
      }
    } catch (e) {
      log('Error fetching admin subscription: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await changePasswordUseCase(
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      _error = e.toString().contains('Exception: ')
          ? e.toString().split('Exception: ')[1]
          : 'Failed to change password';
      notifyListeners();
      return false;
    }
  }
}
