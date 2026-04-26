import 'package:dartz/dartz.dart';

import '../repositories/auth_repository.dart';
import '../entities/user_entity.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

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