// Declares repository contracts for main.

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';

/// Defines main feature data operations.
abstract class MainRepository {
  /// Returns the nullable profile image URL for a user.
  Future<Either<Failure, String?>> getUserProfileImage(String userId);

  /// Updates the latest login timestamp for a user.
  Future<Either<Failure, void>> updateLastLogin(String userId);
}
