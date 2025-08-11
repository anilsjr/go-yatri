import 'package:goyatri/features/auth-firebase/domain/entities/auth_entity.dart';
import 'package:goyatri/features/auth-firebase/domain/repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<AuthEntity> call(String email, String password) async {
    return await repository.signUpWithEmailAndPassword(email, password);
  }
}
