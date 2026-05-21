import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';
import '../entities/user_entity.dart';

/// Runs the signup use case operation.
class SignupUseCase {
  final AuthRepository repository;

  /// Runs the signup use case operation.
  SignupUseCase(this.repository);

  /// Validates input and delegates the signup request to the repository.
  Future<Either<AuthFailure, UserEntity>> execute({
    required String email,
    required String password,
    required String name,
    required String gender,
    required String ageGroupId,
    required String ageGroupName,
  }) async {
    // Checks required fields before repository access.
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
    if (ageGroupId.isEmpty) {
      return Left(AuthFailure(message: 'Age group cannot be empty'));
    }
    if (ageGroupName.isEmpty) {
      return Left(AuthFailure(message: 'Age group cannot be empty'));
    }

    // Checks password strength rules before submission.
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
      ageGroupId: ageGroupId,
      ageGroupName: ageGroupName,
    );
  }
}
