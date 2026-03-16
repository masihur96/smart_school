import 'dart:developer';

import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<UserEntity> call(String email, String password) {
    log("Login usecase call email: $email pass: $password");
    return repository.login(email,password);
  }
}
