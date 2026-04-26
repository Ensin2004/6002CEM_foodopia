import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/profile_repository.dart';

class UpdateUserGenderUseCase {
  final ProfileRepository repository;

  UpdateUserGenderUseCase(this.repository);

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