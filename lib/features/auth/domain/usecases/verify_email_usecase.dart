// Executes the verify email use case.

import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';

/// Runs the verify email use case operation.
class VerifyEmailUseCase {
  final AuthRepository repository;

  /// Runs the verify email use case operation.
  VerifyEmailUseCase(this.repository);

  /// Validates input and delegates the verify email request to the repository.
  Future<Either<AuthFailure, bool>> execute() async {
    return await repository.checkEmailVerified();
  }
}
