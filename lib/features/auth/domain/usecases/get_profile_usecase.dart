import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class GetProfileUseCase {
  final AuthRepository repository;

  GetProfileUseCase(this.repository);

  Future<UserEntity> call() async {
    return await repository.getProfile();
  }
}
