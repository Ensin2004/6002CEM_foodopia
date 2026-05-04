// Executes the update profile image use case.

import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../repositories/profile_repository.dart';

/// Runs the update profile image use case operation.
class UpdateProfileImageUseCase {
  final ProfileRepository repository;

  /// Runs the update profile image use case operation.
  UpdateProfileImageUseCase(this.repository);

  /// Validates input and delegates the update profile image request to the repository.
  Future<Either<Failure, void>> execute({
    required String uid,
    required File imageFile,
  }) async {
    if (uid.isEmpty) {
      return Left(ValidationFailure(message: 'User ID cannot be empty'));
    }
    if (!await imageFile.exists()) {
      return Left(ValidationFailure(message: 'Image file does not exist'));
    }
    return await repository.updateProfileImage(uid, imageFile.path);
  }
}
