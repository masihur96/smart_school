import 'dart:developer';

import 'package:smart_school/configs/network/data_provider.dart';
import 'package:smart_school/core/constants/api_path.dart';
import 'package:smart_school/core/utils/storage_service.dart';

import '../models/auth_response_model.dart';

class AuthRemoteDataSource {
  final DataProvider _dataProvider;

  AuthRemoteDataSource(this._dataProvider);

  /// Logs in a user and stores the token in secure storage.
  Future<AuthResponseModel> login(String email, String password) async {
    final response = await _dataProvider.performRequest(
      'POST',
      APIPath.login,
      data: {'identifier': email, 'password': password},
    );

    log('Login response: ${response?.statusCode} - ${response?.data}');

    if (response == null || response.statusCode == null) {
      throw Exception('No response from server');
    }

    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      // The API wraps the payload inside a nested 'data' key:
      // { message, statusCode, data: { accessToken, refreshToken, user } }
      final outerData = response.data;
      final innerData = outerData['data'] ?? outerData;

      // Save token
      final token = innerData['accessToken'] ?? innerData['token'];
      if (token != null) {
        await StorageService.saveToken(token);
        log('Token saved successfully');
      } else {
        log('Warning: No token found in login response');
      }

      // Also save refresh token if present
      final refreshToken = innerData['refreshToken'];
      if (refreshToken != null) {
        await StorageService.saveSmallToken(refreshToken);
      }

      final userData = innerData['user'] ?? innerData;
      return AuthResponseModel.fromJson(userData);
    } else {
      final message = response.data?['message'] ?? 'Login failed';
      throw Exception(message);
    }
  }

  /// Registers a new user with the given details.
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String schoolId,
    required String phone,
  }) async {
    final payload = {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'schoolId': schoolId,
      'phone': phone,
      "lat": 0,
      "lon": 0,
      "radius": 0,
    };

    log('Register payload: $payload');

    final response = await _dataProvider.performRequest(
      'POST',
      APIPath.register,
      data: payload,
    );

    log('Register response: ${response?.statusCode} - ${response?.data}');

    if (response == null || response.statusCode == null) {
      throw Exception('No response from server');
    }

    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      return true;
    } else {
      final message = response.data?['message'] ?? 'Registration failed';
      throw Exception(message);
    }
  }

  /// Sends a forget-password request.
  Future<bool> forgetPassword(String email) async {
    final response = await _dataProvider.performRequest(
      'POST',
      '${APIPath.baseUrl}/auth/forgot-password',
      data: {'email': email},
    );

    if (response == null || response.statusCode == null) {
      throw Exception('No response from server');
    }

    return response.statusCode! >= 200 && response.statusCode! < 300;
  }

  /// Forces a password reset using a temporary token.
  Future<bool> forceResetPassword(
    String newPassword,
    String confirmPassword,
    String tempToken,
  ) async {
    final response = await _dataProvider.performRequest(
      'POST',
      '${APIPath.baseUrl}/auth/reset-password',
      data: {'newPassword': newPassword, 'confirmPassword': confirmPassword},
      header: {'Authorization': 'Bearer $tempToken'},
    );

    if (response == null || response.statusCode == null) {
      throw Exception('No response from server');
    }

    return response.statusCode! >= 200 && response.statusCode! < 300;
  }

  /// Fetches the current user's profile.
  Future<AuthResponseModel> getProfile() async {
    final token = await StorageService.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await _dataProvider.performRequest(
      'GET',
      APIPath.profile,
      header: {'Authorization': 'Bearer $token'},
    );

    log('Get profile response: ${response?.statusCode} - ${response?.data}');

    if (response == null || response.statusCode == null) {
      throw Exception('No response from server');
    }

    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      // API wraps payload: { message, statusCode, data: { id, role, ... } }
      final outerData = response.data;
      final userData = outerData['data'] ?? outerData;
      return AuthResponseModel.fromJson(userData);
    } else {
      final message = response.data?['message'] ?? 'Failed to fetch profile';
      throw Exception(message);
    }
  }

  /// Changes the current user's password.
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final token = await StorageService.getToken();
    if (token == null) {
      throw Exception('No authentication token found');
    }

    final response = await _dataProvider.performRequest(
      'POST',
      APIPath.changePassword,
      data: {'oldPassword': oldPassword, 'newPassword': newPassword},
      header: {'Authorization': 'Bearer $token'},
    );

    if (response == null || response.statusCode == null) {
      throw Exception('No response from server');
    }

    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      return true;
    } else {
      final message = response.data?['message'] ?? 'Failed to change password';
      throw Exception(message);
    }
  }
}
