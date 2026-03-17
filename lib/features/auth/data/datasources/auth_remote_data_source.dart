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
      data: {'email': email, 'password': password},
    );

    log('Login response: ${response?.statusCode} - ${response?.data}');

    if (response == null || response.statusCode == null) {
      throw Exception('No response from server');
    }

    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      final data = response.data;

      // Save token if returned
      final token = data['accessToken'] ?? data['token'];
      if (token != null) {
        await StorageService.saveToken(token);
      }

      return AuthResponseModel.fromJson(data['user'] ?? data);
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
      return AuthResponseModel.fromJson(response.data);
    } else {
      final message = response.data?['message'] ?? 'Failed to fetch profile';
      throw Exception(message);
    }
  }
}
