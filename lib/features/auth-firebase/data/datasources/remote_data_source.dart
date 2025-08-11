import 'package:firebase_auth/firebase_auth.dart';
import '../models/auth_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthModel> signInWithEmailAndPassword(String email, String password);
  Future<AuthModel> signUpWithEmailAndPassword(String email, String password);
  Future<void> signOut();
  Future<void> sendPasswordResetEmail(String email);
  Future<void> sendEmailVerification();
  Future<AuthModel?> getCurrentUser();
  Stream<AuthModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;

  AuthRemoteDataSourceImpl({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Future<AuthModel> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential result = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      if (result.user != null) {
        return AuthModel.fromFirebaseUser(result.user!);
      } else {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Sign in failed: User is null',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AuthModel> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential result = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (result.user != null) {
        return AuthModel.fromFirebaseUser(result.user!);
      } else {
        throw FirebaseAuthException(
          code: 'user-creation-failed',
          message: 'Sign up failed: User is null',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
      } else {
        throw FirebaseAuthException(
          code: 'no-current-user',
          message: 'No current user found',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<AuthModel?> getCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        return AuthModel.fromFirebaseUser(user);
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  @override
  Stream<AuthModel?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((User? user) {
      if (user != null) {
        return AuthModel.fromFirebaseUser(user);
      }
      return null;
    });
  }
}
