import 'package:goyatri/features/auth-firebase/domain/entities/auth_entity.dart';
import 'package:goyatri/features/auth-firebase/domain/repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  Future<AuthEntity> call(String email, String password) async {
    return await repository.signInWithEmailAndPassword(email, password);
  }
}
