import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  Future<bool> call({
    required String name,
    required String email,
    required String password,
    required String role,
    required String schoolId,
    required String phone,
  }) {
    return repository.register(
      name: name,
      email: email,
      password: password,
      role: role,
      schoolId: schoolId,
      phone: phone,
    );
  }
}
