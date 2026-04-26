import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';
import '../entities/user_entity.dart';

class SignupUseCase {
  final AuthRepository repository;

  SignupUseCase(this.repository);

  Future<Either<AuthFailure, UserEntity>> execute({
    required String email,
    required String password,
    required String name,
    required String gender,
    required String countryId,
  }) async {
    // Validation
    if (email.isEmpty) {
      return Left(AuthFailure(message: 'Email cannot be empty'));
    }
    if (password.isEmpty) {
      return Left(AuthFailure(message: 'Password cannot be empty'));
    }
    if (name.isEmpty) {
      return Left(AuthFailure(message: 'Name cannot be empty'));
    }
    if (gender.isEmpty) {
      return Left(AuthFailure(message: 'Gender cannot be empty'));
    }
    if (countryId.isEmpty) {
      return Left(AuthFailure(message: 'Country cannot be empty'));
    }

    // Password strength validation
    if (password.length < 12) {
      return Left(AuthFailure(message: 'Password must be at least 12 characters'));
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return Left(AuthFailure(message: 'Password must contain at least one uppercase letter'));
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return Left(AuthFailure(message: 'Password must contain at least one lowercase letter'));
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return Left(AuthFailure(message: 'Password must contain at least one number'));
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return Left(AuthFailure(message: 'Password must contain at least one special character'));
    }

    return await repository.signup(
      email: email,
      password: password,
      name: name,
      gender: gender,
      countryId: countryId,
    );
  }
}