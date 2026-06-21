// Executes the update user name use case.

import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../repositories/profile_repository.dart';

/// Runs the update user name use case operation.
/// Handles updating a user's name with validation.
class UpdateUserNameUseCase {
  /// Repository instance for data operations.
  final ProfileRepository repository;

  /// Runs the update user name use case operation.
  UpdateUserNameUseCase(this.repository);

  /// Validates input and delegates the update user name request to the repository.
  ///
  /// [uid] is the ID of the user.
  /// [name] is the new name to set.
  /// Returns either a failure or void on success.
  Future<Either<Failure, void>> execute({
    required String uid,
    required String name,
  }) async {
    // Validate the user ID.
    if (uid.isEmpty) {
      return Left(ValidationFailure(message: 'User ID cannot be empty'));
    }

    // Validate the name is not empty.
    if (name.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Name cannot be empty'));
    }

    // Validate the name length.
    if (name.length > 100) {
      return Left(ValidationFailure(message: 'Name cannot exceed 100 characters'));
    }

    // Delegate to repository to update the name.
    return await repository.updateUserName(uid, name.trim());
  }
}