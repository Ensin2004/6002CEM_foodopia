// Executes the login use case.

import 'package:dartz/dartz.dart';

import '../repositories/auth_repository.dart';
import '../entities/user_entity.dart';

/// Runs the login use case operation.
/// Handles user login with email and password validation.
class LoginUseCase {
  /// Repository instance for data operations.
  final AuthRepository repository;

  /// Runs the login use case operation.
  LoginUseCase(this.repository);

  /// Validates input and delegates the login request to the repository.
  ///
  /// [email] is the user's email address.
  /// [password] is the user's password.
  /// Returns either an auth failure or a user entity on success.
  Future<Either<AuthFailure, UserEntity>> execute({
    required String email,
    required String password,
  }) async {
    // Validate the email.
    if (email.isEmpty) {
      return Left(AuthFailure(message: 'Email cannot be empty'));
    }

    // Validate the password.
    if (password.isEmpty) {
      return Left(AuthFailure(message: 'Password cannot be empty'));
    }

    // Delegate to repository for login.
    return await repository.login(email: email, password: password);
  }
}