import 'package:dartz/dartz.dart';

import '../repositories/auth_repository.dart';

/// Use case for requesting a password reset email.
/// Encapsulates the business logic for sending password reset emails.
class RequestPasswordResetUseCase {
  /// Repository instance for data operations.
  final AuthRepository _repository;

  /// Creates a new request password reset use case instance.
  const RequestPasswordResetUseCase(this._repository);

  /// Executes the use case with the given email.
  ///
  /// [email] is the email address to send the reset link to.
  /// Returns either an auth failure or void on success.
  Future<Either<AuthFailure, void>> execute({required String email}) {
    // Delegate to repository to request password reset.
    return _repository.requestPasswordReset(email: email);
  }
}