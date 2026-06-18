import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../repositories/profile_repository.dart';

/// Updates a user's selected age group.
/// Handles age group update with validation.
class UpdateUserAgeGroupUseCase {
  /// Repository instance for data operations.
  final ProfileRepository repository;

  /// Creates a new update user age group use case instance.
  UpdateUserAgeGroupUseCase(this.repository);

  /// Executes the use case with the given parameters.
  ///
  /// [uid] is the ID of the user.
  /// [ageGroupId] is the ID of the age group.
  /// [ageGroupName] is the name of the age group.
  /// Returns either a failure or void on success.
  Future<Either<Failure, void>> execute({
    required String uid,
    required String ageGroupId,
    required String ageGroupName,
  }) async {
    // Validate the user ID.
    if (uid.isEmpty) {
      return Left(ValidationFailure(message: 'User ID cannot be empty'));
    }

    // Validate the age group values.
    if (ageGroupId.trim().isEmpty || ageGroupName.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Age group cannot be empty'));
    }

    // Delegate to repository to update the age group.
    return await repository.updateUserAgeGroup(
      uid,
      ageGroupId.trim(),
      ageGroupName.trim(),
    );
  }
}