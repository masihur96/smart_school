import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
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

  List<User> _admins = [];
  List<User> get admins => _admins;

  bool _isLoadingAdmins = false;
  bool get isLoadingAdmins => _isLoadingAdmins;

  bool get isSubscriptionValid {
    if (_adminSubscription == null) return false;
    if (!_adminSubscription!.isActive) return false;

    try {
      final endDate = DateTime.parse(_adminSubscription!.endDate);
      log("_adminSubscription:: ${endDate.isAfter(DateTime.now())}");
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
          classIds: profile.classIds,
          sectionIds: profile.sectionIds,
          phone: profile.phone,
          rollNumber: profile.rollNumber,
          designation: profile.designation,
          isActive: profile.isActive,
          avatar: profile.avatar,
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

        unawaited(
          FirebaseAnalytics.instance
              .setUserId(id: _user!.id)
              .catchError((e) => log('setUserId error: $e')),
        );

        // FCM topic subscription & token registration are fire-and-forget.
        // They do NOT block navigation out of the splash screen.
        unawaited(
          NotificationService()
              .subscribeToUserTopics(_user!)
              .catchError((e) => log('subscribeToUserTopics error: $e')),
        );
        unawaited(
          NotificationService().registerTokenToBackend().catchError(
            (e) => log('registerTokenToBackend error: $e'),
          ),
        );
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
      await loginUseCase(email.toLowerCase(), password);

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
        classIds: profile.classIds,
        sectionIds: profile.sectionIds,
        phone: profile.phone,
        rollNumber: profile.rollNumber,
        designation: profile.designation,
        isActive: profile.isActive,
        avatar: profile.avatar,
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

      unawaited(
        FirebaseAnalytics.instance
            .setUserId(id: _user!.id)
            .catchError((e) => log('setUserId error: $e')),
      );
      unawaited(
        FirebaseAnalytics.instance
            .logLogin(loginMethod: 'email')
            .catchError((e) => log('logLogin error: $e')),
      );

      // FCM topic subscription & token registration are fire-and-forget.
      // They do NOT block the login response.
      unawaited(
        NotificationService()
            .subscribeToUserTopics(_user!)
            .catchError((e) => log('subscribeToUserTopics error: $e')),
      );
      unawaited(
        NotificationService().registerTokenToBackend().catchError(
          (e) => log('registerTokenToBackend error: $e'),
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

      if (success) {
        unawaited(
          FirebaseAnalytics.instance
              .logSignUp(signUpMethod: 'email')
              .catchError((e) => log('logSignUp error: $e')),
        );
      }

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
    // Capture user to unsubscribe in background
    final userToUnsubscribe = _user;

    // Clear state synchronously so that immediate navigations (e.g. to LoginScreen)
    // don't see a stale non-null user and auto-navigate back to the dashboard.
    _user = null;
    _adminSubscription = null;
    notifyListeners();

    unawaited(
      FirebaseAnalytics.instance
          .logEvent(name: 'logout')
          .catchError((e) => log('logEvent logout error: $e')),
    );
    unawaited(
      FirebaseAnalytics.instance
          .setUserId(id: null)
          .catchError((e) => log('setUserId null error: $e')),
    );

    // Clear local storage immediately to prevent race conditions with new logins.
    await StorageService.clear();

    if (userToUnsubscribe != null) {
      try {
        await NotificationService().unsubscribeFromUserTopics(
          userToUnsubscribe,
        );
      } catch (e) {
        log("Logout unsubscription error: $e");
      }
    }
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
      final endDate = formatIso(now.add(const Duration(days: 30)));

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

  /// Fetches all available pricing plans, finds the first free plan, and
  /// auto-assigns it to the current school. Returns true on success.
  Future<bool> autoAssignFreePlan() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      // Fetch all plans
      final response = await DataProvider().performRequest(
        'GET',
        APIPath.pricingPlans,
        header: {'Authorization': 'Bearer $token'},
      );

      if (response == null || response.statusCode != 200) {
        log('Failed to fetch pricing plans: ${response?.statusCode}');
        return false;
      }

      final dynamic rawData = response.data;
      final List dataList = rawData is List
          ? rawData
          : (rawData is Map ? (rawData['data'] ?? []) : []);

      // Find the free plan
      final freePlanJson = dataList.firstWhere((json) {
        final price = json['pricePerMonth']?.toString() ?? '0';
        final name = (json['name'] ?? '').toString().toLowerCase();
        return price == '0' || name.contains('free');
      }, orElse: () => null);

      if (freePlanJson == null) {
        log('No free pricing plan found');
        return false;
      }

      final freePlanId = freePlanJson['id']?.toString();
      if (freePlanId == null) {
        log('Free plan has no ID');
        return false;
      }

      log('Auto-assigning free plan: $freePlanId');
      return await assignPricingPlan(freePlanId, true);
    } catch (e) {
      log('Exception in autoAssignFreePlan: $e');
      return false;
    }
  }

  String formatIso(DateTime date) {
    final iso = date.toUtc().toIso8601String();
    return iso.contains('.') ? iso.split('.').first + '.000Z' : iso + '.000Z';
  }

  Future<void> fetchAdmins() async {
    if (_user?.schoolId == null) return;
    _isLoadingAdmins = true;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) return;

      final response = await DataProvider().performRequest(
        'GET',
        APIPath.fetchUsers,
        query: {'role': 'admin', 'limit': '50'},
        header: {'Authorization': 'Bearer $token'},
      );

      if (response != null && response.statusCode == 200) {
        final dynamic rawData = response.data['data'];
        final List<dynamic> data = rawData is List
            ? rawData
            : (rawData is Map ? (rawData['data'] ?? []) : []);

        _admins = data
            .map((item) {
              try {
                return User.fromJson(item);
              } catch (e) {
                log('Error parsing admin: $e');
                return null;
              }
            })
            .whereType<User>()
            .toList();
      }
    } catch (e) {
      log('Error fetching admins: $e');
    } finally {
      _isLoadingAdmins = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Retry fetching the admin subscription (e.g. after a transient network
  /// failure during biometric login). Notifies listeners when done.
  Future<void> refreshSubscription() async {
    if (_user?.schoolId == null) return;
    await _fetchAdminSubscription(_user!.schoolId!);
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

  Future<bool> updateProfile({
    required String name,
    required String phone,
    String? profileImageUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');
      if (_user == null) throw Exception('No user found');

      final Map<String, dynamic> dataMap = {'name': name, 'phone': phone};
      if (profileImageUrl != null) {
        dataMap['image'] = profileImageUrl;
        dataMap['profileImageUrl'] = profileImageUrl;
        dataMap['avatar'] = profileImageUrl;
      }
      dynamic requestData = dataMap;

      final response = await DataProvider().performRequest(
        'PUT',
        '${APIPath.register}/${_user!.id}',
        header: {'Authorization': 'Bearer $token'},
        data: requestData,
      );

      if (response != null && response.statusCode == 200) {
        log('Profile updated successfully');
        // Refresh profile data
        await checkAuthStatus();
        return true;
      } else {
        _error = 'Failed to update profile: ${response?.statusCode}';
        log('Error updating profile: ${response?.data}');
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      log('Exception updating profile: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSchoolProfile({
    required String name,
    required String address,
    String? avatar,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');
      if (_user?.schoolId == null) throw Exception('No school found');

      final Map<String, dynamic> requestData = {
        'name': name,
        'address': address,
      };
      if (avatar != null && avatar.isNotEmpty) {
        requestData['avatar'] = avatar;
      }

      final response = await DataProvider().performRequest(
        'PUT',
        '${APIPath.baseUrl}/admin/schools/${_user!.schoolId}',
        header: {'Authorization': 'Bearer $token'},
        data: requestData,
      );

      if (response != null && response.statusCode == 200) {
        log('School profile updated successfully');
        await checkAuthStatus();
        return true;
      } else {
        _error = 'Failed to update school profile: ${response?.statusCode}';
        log('Error updating school profile: ${response?.data}');
        return false;
      }
    } catch (e) {
      _error = 'Error: $e';
      log('Exception updating school profile: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteAccount() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');
      if (_user == null) throw Exception('No user found');

      final response = await DataProvider().performRequest(
        'DELETE',
        APIPath.deleteAdminUser(_user!.id),
        header: {'Authorization': 'Bearer $token', 'accept': '*/*'},
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 204)) {
        log('Account deleted successfully');
        _isLoading = false;
        notifyListeners();
        await logout();
        return true;
      } else {
        _error = 'Failed to delete account: ${response?.statusCode}';
        log('Error deleting account: ${response?.data}');
        return false;
      }
    } catch (e) {
      _error = 'Error deleting account: $e';
      log('Exception deleting account: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadProfileImage(File imageFile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await DataProvider().performRequest(
        'POST',
        'https://smart-school-backend-production.up.railway.app/general/upload',
        header: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        },
        data: formData,
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final url = response.data['data']['url'];
        if (url != null) {
          log('Image uploaded successfully: $url');
          return await updateProfile(
            name: _user!.name,
            phone: _user!.phone ?? '',
            profileImageUrl: url,
          );
        } else {
          throw Exception('URL not found in response');
        }
      } else {
        _error = 'Failed to upload image: ${response?.statusCode}';
        log('Error uploading image: ${response?.data}');
        return false;
      }
    } catch (e) {
      _error = 'Error uploading image: $e';
      log('Exception uploading image: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> uploadSchoolProfileImage(File imageFile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await StorageService.getToken();
      if (token == null) throw Exception('No authentication token found');
      if (_user?.schoolId == null) throw Exception('No school found');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await DataProvider().performRequest(
        'POST',
        'https://smart-school-backend-production.up.railway.app/general/upload',
        header: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'multipart/form-data',
        },
        data: formData,
      );

      if (response != null &&
          (response.statusCode == 200 || response.statusCode == 201)) {
        final url = response.data['data']['url'];
        if (url != null) {
          log('School image uploaded successfully: $url');
          return await updateSchoolProfile(
            name: _user!.school?.name ?? '',
            address: _user!.school?.address ?? '',
            avatar: url,
          );
        } else {
          throw Exception('URL not found in response');
        }
      } else {
        _error = 'Failed to upload school image: ${response?.statusCode}';
        log('Error uploading school image: ${response?.data}');
        return false;
      }
    } catch (e) {
      _error = 'Error uploading school image: $e';
      log('Exception uploading school image: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
