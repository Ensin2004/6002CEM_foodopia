// Executes the get user profile use case.

import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../entities/user_profile.dart';
import '../../repositories/profile_repository.dart';

/// Loads data for the get user profile use case operation.
class GetUserProfileUseCase {
  final ProfileRepository repository;

  /// Loads data for the get user profile use case operation.
  GetUserProfileUseCase(this.repository);

  /// Validates input and delegates the get user profile request to the repository.
  Future<Either<Failure, UserProfile>> execute(String uid) async {
    if (uid.isEmpty) {
      return Left(ValidationFailure(message: 'User ID cannot be empty'));
    }
    return await repository.getUserProfile(uid);
  }
}
