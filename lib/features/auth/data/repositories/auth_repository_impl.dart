import 'dart:developer';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserEntity> login(String email, String password) async {
    final result = await remoteDataSource.login(email, password);

    log("result from auth repository impl: $result");

    return UserEntity(
      id: result.id,
      name: result.name,
      email: result.email,
      role: result.role,
      schoolId: result.schoolId,
      phone: result.phone,
    );
  }

  @override
  Future<UserEntity> getProfile() async {
    final result = await remoteDataSource.getProfile();
    return UserEntity(
      id: result.id,
      name: result.name,
      email: result.email,
      role: result.role,
      schoolId: result.schoolId,
      phone: result.phone,
    );
  }

  @override
  Future<bool> forgetPassword(String email) {
    return remoteDataSource.forgetPassword(email);
  }

  @override
  Future<bool> forceResetPassword(
    String newPassword,
    String confirmPassword,
  ) async {
    // This would typically involve a temporary token check or session
    return false; // Not fully implemented in the current scope
  }

  @override
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String schoolId,
    required String phone,
  }) async {
    return await remoteDataSource.register(
      name: name,
      email: email,
      password: password,
      role: role,
      schoolId: schoolId,
      phone: phone,
    );
  }

  @override
  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    return await remoteDataSource.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }
}
