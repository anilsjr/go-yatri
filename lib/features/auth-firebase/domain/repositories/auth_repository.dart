import 'package:goyatri/features/auth-firebase/domain/entities/auth_entity.dart';

abstract class AuthRepository {
  Future<AuthEntity?> getCurrentUser();
  Future<AuthEntity> signInWithEmailAndPassword(String email, String password);
  Future<AuthEntity> signUpWithEmailAndPassword(String email, String password);
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendEmailVerification();
  Future<void> updateDisplayName(String displayName);
  Future<void> updatePassword(String newPassword);
  Stream<AuthEntity?> get authStateChanges;
}
