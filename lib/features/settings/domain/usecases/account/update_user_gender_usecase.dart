// Executes the update user gender use case.

import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../repositories/profile_repository.dart';

/// Runs the update user gender use case operation.
/// Handles updating a user's gender with validation.
class UpdateUserGenderUseCase {
  /// Repository instance for data operations.
  final ProfileRepository repository;

  /// Runs the update user gender use case operation.
  UpdateUserGenderUseCase(this.repository);

  /// Validates input and delegates the update user gender request to the repository.
  ///
  /// [uid] is the ID of the user.
  /// [gender] is the gender value to set.
  /// Returns either a failure or void on success.
  Future<Either<Failure, void>> execute({
    required String uid,
    required String gender,
  }) async {
    // Validate the user ID.
    if (uid.isEmpty) {
      return Left(ValidationFailure(message: 'User ID cannot be empty'));
    }

    // Validate the gender value.
    if (gender.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Gender cannot be empty'));
    }

    // Delegate to repository to update the gender.
    return await repository.updateUserGender(uid, gender.trim());
  }
}