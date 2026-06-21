// Executes the update profile image use case.

import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../repositories/profile_repository.dart';

/// Runs the update profile image use case operation.
/// Handles updating a user's profile image with validation.
class UpdateProfileImageUseCase {
  /// Repository instance for data operations.
  final ProfileRepository repository;

  /// Runs the update profile image use case operation.
  UpdateProfileImageUseCase(this.repository);

  /// Validates input and delegates the update profile image request to the repository.
  ///
  /// [uid] is the ID of the user.
  /// [imageFile] is the image file to upload.
  /// Returns either a failure or void on success.
  Future<Either<Failure, void>> execute({
    required String uid,
    required File imageFile,
  }) async {
    // Validate the user ID.
    if (uid.isEmpty) {
      return Left(ValidationFailure(message: 'User ID cannot be empty'));
    }

    // Validate that the image file exists.
    if (!await imageFile.exists()) {
      return Left(ValidationFailure(message: 'Image file does not exist'));
    }

    // Delegate to repository to update the profile image.
    return await repository.updateProfileImage(uid, imageFile.path);
  }
}