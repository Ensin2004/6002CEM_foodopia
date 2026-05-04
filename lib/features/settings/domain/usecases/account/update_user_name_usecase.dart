// Executes the update user name use case.

import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../repositories/profile_repository.dart';

/// Runs the update user name use case operation.
class UpdateUserNameUseCase {
  final ProfileRepository repository;

  /// Runs the update user name use case operation.
  UpdateUserNameUseCase(this.repository);

  /// Validates input and delegates the update user name request to the repository.
  Future<Either<Failure, void>> execute({
    required String uid,
    required String name,
  }) async {
    if (uid.isEmpty) {
      return Left(ValidationFailure(message: 'User ID cannot be empty'));
    }
    if (name.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Name cannot be empty'));
    }
    if (name.length > 100) {
      return Left(ValidationFailure(message: 'Name cannot exceed 100 characters'));
    }
    return await repository.updateUserName(uid, name.trim());
  }
}
