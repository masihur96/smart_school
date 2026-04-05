import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../core/constants/api_path.dart';

class AuthService {
  final Dio _dio = Dio();

  Future<User?> login(String email, String password) async {
    try {
      final response = await _dio.post(
        APIPath.login,
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Assuming the response contains the user data directly or in a 'user' field
        // And potentially a token that should be stored
        final data = response.data;
        if (data['user'] != null) {
          return User.fromJson(data['user']);
        }
        return User.fromJson(data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String schoolId,
    required String phone,
  }) async {
    try {
      final response = await _dio.post(
        APIPath.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
          'schoolId': schoolId,
          'phone': phone,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data['user'] != null) {
          return User.fromJson(data['user']);
        }
        return User.fromJson(data);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    // Implement logout logic (e.g., clearing tokens)
  }
}
