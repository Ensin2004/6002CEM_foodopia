// Declares repository contracts for password.

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

/// Defines behavior for password repository.
abstract class PasswordRepository {
  /// Runs the change password operation.
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}
