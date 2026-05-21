// Executes the update user gender use case.

import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../repositories/profile_repository.dart';

/// Runs the update user gender use case operation.
class UpdateUserGenderUseCase {
  final ProfileRepository repository;

  /// Runs the update user gender use case operation.
  UpdateUserGenderUseCase(this.repository);

  /// Validates input and delegates the update user gender request to the repository.
  Future<Either<Failure, void>> execute({
    required String uid,
    required String gender,
  }) async {
    if (uid.isEmpty) {
      return Left(ValidationFailure(message: 'User ID cannot be empty'));
    }
    if (gender.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Gender cannot be empty'));
    }
    return await repository.updateUserGender(uid, gender.trim());
  }
}
