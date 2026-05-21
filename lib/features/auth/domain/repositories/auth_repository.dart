// Declares repository contracts for auth.

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

export '../../../../core/error/failures.dart' show AuthFailure;

/// Defines behavior for auth repository.
abstract class AuthRepository {
  /// Runs the login operation.
  Future<Either<AuthFailure, UserEntity>> login({
    required String email,
    required String password,
  });

  /// Runs the signup operation.
  Future<Either<AuthFailure, UserEntity>> signup({
    required String email,
    required String password,
    required String name,
    required String gender,
    required String ageGroupId,
    required String ageGroupName,
  });

  /// Runs the send email verification operation.
  Future<Either<AuthFailure, void>> sendEmailVerification();

  /// Handles the check email verified operation.
  Future<Either<AuthFailure, bool>> checkEmailVerified();

  /// Handles the resend verification email operation.
  Future<Either<AuthFailure, void>> resendVerificationEmail();

  /// Loads configured age groups.
  Future<Either<AuthFailure, List<Map<String, dynamic>>>> getAgeGroups();

  /// Handles the logout operation.
  Future<Either<AuthFailure, void>> logout();
}
