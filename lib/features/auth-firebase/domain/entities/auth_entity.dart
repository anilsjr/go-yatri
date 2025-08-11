class AuthEntity {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final bool isEmailVerified;

  const AuthEntity({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.isEmailVerified,
  });

  AuthEntity copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    bool? isEmailVerified,
  }) {
    return AuthEntity(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthEntity &&
        other.uid == uid &&
        other.email == email &&
        other.displayName == displayName &&
        other.photoURL == photoURL &&
        other.isEmailVerified == isEmailVerified;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        email.hashCode ^
        displayName.hashCode ^
        photoURL.hashCode ^
        isEmailVerified.hashCode;
  }

  @override
  String toString() {
    return 'AuthEntity(uid: $uid, email: $email, displayName: $displayName, photoURL: $photoURL, isEmailVerified: $isEmailVerified)';
  }
}
