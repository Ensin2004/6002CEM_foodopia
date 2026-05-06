import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../repositories/profile_repository.dart';

/// Updates a user's selected age group.
class UpdateUserAgeGroupUseCase {
  final ProfileRepository repository;

  UpdateUserAgeGroupUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String uid,
    required String ageGroupId,
    required String ageGroupName,
  }) async {
    if (uid.isEmpty) {
      return Left(ValidationFailure(message: 'User ID cannot be empty'));
    }
    if (ageGroupId.trim().isEmpty || ageGroupName.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Age group cannot be empty'));
    }
    return await repository.updateUserAgeGroup(
      uid,
      ageGroupId.trim(),
      ageGroupName.trim(),
    );
  }
}
