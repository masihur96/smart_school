import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:smart_school/core/utils/storage_service.dart';

import '../../../configs/network/data_provider.dart';
import '../../../core/constants/api_path.dart';
import '../../../models/user_model.dart';
import '../../../services/notification_service.dart';
import '../../super_admin/models/subscription_model.dart';
import '../domain/usecases/change_password_usecase.dart';
import '../domain/usecases/get_profile_usecase.dart';
import '../domain/usecases/login_usecase.dart';
import '../domain/usecases/register_usecase.dart';

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

  bool get isSubscriptionValid {
    if (_adminSubscription == null) return false;
    if (!_adminSubscription!.isActive) return false;

    print("_adminSubscription:: ${_adminSubscription!.endDate}");
    print("_adminSubscription:: ${_adminSubscription!.lastStudentCount}");
    print(
      "_adminSubscription:: ${_adminSubscription!.pricingPlan?.maxStudents ?? 0}",
    );
    try {
      final endDate = DateTime.parse(_adminSubscription!.endDate);
      print("_adminSubscription:: ${endDate.isAfter(DateTime.now())}");
      return endDate.isAfter(DateTime.now());
    } catch (e) {
      return false;
    }
  }

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
          school: profile.school,
        );

        if ((_user?.role == UserRole.admin ||
                _user?.role == UserRole.teacher) &&
            _user?.schoolId != null) {
          await _fetchAdminSubscription(_user!.schoolId!);
        }

        // Register FCM Token
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await NotificationService().registerToken(fcmToken);
          await NotificationService().subscribeToUserTopics(_user!);
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
        school: profile.school,
      );

      if ((_user?.role == UserRole.admin || _user?.role == UserRole.teacher) &&
          _user?.schoolId != null) {
        await _fetchAdminSubscription(_user!.schoolId!);
      }

      // Register FCM Token
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await NotificationService().registerToken(fcmToken);
        await NotificationService().subscribeToUserTopics(_user!);
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
    if (_user != null) {
      await NotificationService().unsubscribeFromUserTopics(_user!);
    }
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
        log(
          'Fetched admin subscription for school: $schoolId (Active: ${_adminSubscription?.isActive})',
        );
      }
    } catch (e) {
      log('Error fetching admin subscription: $e');
    }
  }

  Future<bool> assignPricingPlan(String planId, bool isFree) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');
      if (_user?.schoolId == null)
        throw Exception('No school ID found for user');

      final now = DateTime.now().toUtc();

      final startDate = formatIso(now);
      final endDate = formatIso(
        isFree
            ? now.add(const Duration(days: 7))
            : now.add(const Duration(days: 30)),
      );

      final response = await DataProvider().performRequest(
        'POST',
        APIPath.assignSubscription,
        header: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        data: {
          'schoolId': _user!.schoolId,
          'pricingPlanId': planId,
          'startDate': startDate,
          'endDate': endDate,
          'isActive': isFree ? true : false,
        },
      );

      if (response != null &&
          (response.statusCode == 201 || response.statusCode == 200)) {
        log('Subscription assigned successfully');
        // Refresh local subscription state
        await _fetchAdminSubscription(_user!.schoolId!);
        return true;
      } else {
        _error = 'Failed to assign plan: ${response?.statusCode}';
        log('Error assigning subscription: ${response?.data}');
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      log('Exception assigning subscription: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String formatIso(DateTime date) {
    final iso = date.toUtc().toIso8601String();
    return iso.contains('.') ? iso.split('.').first + '.000Z' : iso + '.000Z';
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
