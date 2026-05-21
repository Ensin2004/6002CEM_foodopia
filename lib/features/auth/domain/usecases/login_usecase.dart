// Executes the login use case.

import 'package:dartz/dartz.dart';

import '../repositories/auth_repository.dart';
import '../entities/user_entity.dart';

/// Runs the login use case operation.
class LoginUseCase {
  final AuthRepository repository;

  /// Runs the login use case operation.
  LoginUseCase(this.repository);

  /// Validates input and delegates the login request to the repository.
  Future<Either<AuthFailure, UserEntity>> execute({
    required String email,
    required String password,
  }) async {
    if (email.isEmpty) {
      return Left(AuthFailure(message: 'Email cannot be empty'));
    }
    if (password.isEmpty) {
      return Left(AuthFailure(message: 'Password cannot be empty'));
    }
    return await repository.login(email: email, password: password);
  }
}
