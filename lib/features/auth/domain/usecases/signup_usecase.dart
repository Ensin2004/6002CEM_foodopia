import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';
import '../entities/user_entity.dart';

/// Runs the signup use case operation.
/// Handles user registration with comprehensive validation.
class SignupUseCase {
  /// Repository instance for data operations.
  final AuthRepository repository;

  /// Runs the signup use case operation.
  SignupUseCase(this.repository);

  /// Validates input and delegates the signup request to the repository.
  ///
  /// [email] is the user's email address.
  /// [password] is the user's password.
  /// [name] is the user's full name.
  /// [gender] is the user's gender.
  /// [ageGroupId] is the ID of the selected age group.
  /// [ageGroupName] is the name of the selected age group.
  /// Returns either an auth failure or a user entity on success.
  Future<Either<AuthFailure, UserEntity>> execute({
    required String email,
    required String password,
    required String name,
    required String gender,
    required String ageGroupId,
    required String ageGroupName,
  }) async {
    // =========================================================================
    // REQUIRED FIELD VALIDATION
    // =========================================================================

    // Validate email.
    if (email.isEmpty) {
      return Left(AuthFailure(message: 'Email cannot be empty'));
    }

    // Validate password.
    if (password.isEmpty) {
      return Left(AuthFailure(message: 'Password cannot be empty'));
    }

    // Validate name.
    if (name.isEmpty) {
      return Left(AuthFailure(message: 'Name cannot be empty'));
    }

    // Validate gender.
    if (gender.isEmpty) {
      return Left(AuthFailure(message: 'Gender cannot be empty'));
    }

    // Validate age group ID.
    if (ageGroupId.isEmpty) {
      return Left(AuthFailure(message: 'Age group cannot be empty'));
    }

    // Validate age group name.
    if (ageGroupName.isEmpty) {
      return Left(AuthFailure(message: 'Age group cannot be empty'));
    }

    // =========================================================================
    // PASSWORD STRENGTH VALIDATION
    // =========================================================================

    // Check minimum length.
    if (password.length < 12) {
      return Left(AuthFailure(message: 'Password must be at least 12 characters'));
    }

    // Check for uppercase letter.
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return Left(AuthFailure(message: 'Password must contain at least one uppercase letter'));
    }

    // Check for lowercase letter.
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return Left(AuthFailure(message: 'Password must contain at least one lowercase letter'));
    }

    // Check for number.
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return Left(AuthFailure(message: 'Password must contain at least one number'));
    }

    // Check for special character.
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return Left(AuthFailure(message: 'Password must contain at least one special character'));
    }

    // =========================================================================
    // DELEGATE TO REPOSITORY
    // =========================================================================

    // Delegate to repository for signup.
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