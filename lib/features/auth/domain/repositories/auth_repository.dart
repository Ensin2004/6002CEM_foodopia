import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  // ✅ Change Failure to AuthFailure (more specific)
  Future<Either<AuthFailure, UserEntity>> login({
    required String email,
    required String password,
  });

  Future<Either<AuthFailure, UserEntity>> signup({
    required String email,
    required String password,
    required String name,
    required String gender,
    required String countryId,
  });

  Future<Either<AuthFailure, void>> sendEmailVerification();
  Future<Either<AuthFailure, bool>> checkEmailVerified();
  Future<Either<AuthFailure, void>> resendVerificationEmail();
  Future<Either<AuthFailure, List<Map<String, dynamic>>>> getCountries();
  Future<Either<AuthFailure, void>> logout();
}

// AuthFailure extends Failure
class AuthFailure extends Failure {
  AuthFailure({required super.message, super.code});
}