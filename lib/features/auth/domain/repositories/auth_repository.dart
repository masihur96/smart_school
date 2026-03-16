import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login(String email, String password);
  Future<bool> forgetPassword(String email);
  Future<bool> forceResetPassword(String newPassword, String confirmPassword);
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String schoolId,
    required String phone,
  });
}
