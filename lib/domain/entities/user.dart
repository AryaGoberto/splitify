import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;

  const User({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
  });

  User copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  @override
  List<Object?> get props => [uid, email, displayName, photoUrl];
}
