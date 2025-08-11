import 'package:firebase_auth/firebase_auth.dart';
import 'package:goyatri/features/auth-firebase/domain/entities/auth_entity.dart';
import 'package:goyatri/features/auth-firebase/domain/repositories/auth_repository.dart';
import 'package:goyatri/features/auth-firebase/data/models/auth_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;

  AuthRepositoryImpl({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Future<AuthEntity?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      return AuthModel.fromFirebaseUser(user);
    }
    return null;
  }

  @override
  Future<AuthEntity> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential result = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      if (result.user != null) {
        return AuthModel.fromFirebaseUser(result.user!);
      } else {
        throw Exception('Sign in failed: User is null');
      }
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  @override
  Future<AuthEntity> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential result = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (result.user != null) {
        return AuthModel.fromFirebaseUser(result.user!);
      } else {
        throw Exception('Sign up failed: User is null');
      }
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseAuthException(e);
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      } else {
        throw Exception('No user found or email already verified');
      }
    } catch (e) {
      throw Exception('Email verification failed: $e');
    }
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.updateDisplayName(displayName);
        await user.reload();
      } else {
        throw Exception('No user found');
      }
    } catch (e) {
      throw Exception('Update display name failed: $e');
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw Exception('No user found');
      }
    } catch (e) {
      throw Exception('Update password failed: $e');
    }
  }

  @override
  Stream<AuthEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((User? user) {
      if (user != null) {
        return AuthModel.fromFirebaseUser(user);
      }
      return null;
    });
  }

  Exception _handleFirebaseAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found for this email.');
      case 'wrong-password':
        return Exception('Wrong password provided.');
      case 'email-already-in-use':
        return Exception('An account already exists for this email.');
      case 'weak-password':
        return Exception('The password provided is too weak.');
      case 'invalid-email':
        return Exception('The email address is not valid.');
      case 'user-disabled':
        return Exception('This user account has been disabled.');
      case 'too-many-requests':
        return Exception('Too many requests. Try again later.');
      case 'operation-not-allowed':
        return Exception('Operation not allowed. Please contact support.');
      default:
        return Exception('Authentication failed: ${e.message}');
    }
  }
}
