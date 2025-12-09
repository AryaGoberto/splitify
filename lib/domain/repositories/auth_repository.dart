import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> signIn(String email, String password);
  Future<Either<Failure, User>> signUp(
    String email,
    String password,
    String displayName,
  );
  Future<Either<Failure, void>> signOut();
  Stream<User?> authStateChanges();
  User? getCurrentUser();
}
