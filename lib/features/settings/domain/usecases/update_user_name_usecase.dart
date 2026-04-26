import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/profile_repository.dart';

class UpdateUserNameUseCase {
  final ProfileRepository repository;

  UpdateUserNameUseCase(this.repository);

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