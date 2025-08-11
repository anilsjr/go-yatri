import 'package:firebase_auth/firebase_auth.dart';
import 'package:goyatri/features/auth-firebase/domain/entities/auth_entity.dart';

class AuthModel extends AuthEntity {
  const AuthModel({
    required super.uid,
    required super.email,
    super.displayName,
    super.photoURL,
    required super.isEmailVerified,
  });

  factory AuthModel.fromFirebaseUser(User user) {
    return AuthModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoURL: user.photoURL,
      isEmailVerified: user.emailVerified,
    );
  }

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      photoURL: json['photoURL'],
      isEmailVerified: json['isEmailVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'isEmailVerified': isEmailVerified,
    };
  }

  @override
  AuthModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    bool? isEmailVerified,
  }) {
    return AuthModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}
