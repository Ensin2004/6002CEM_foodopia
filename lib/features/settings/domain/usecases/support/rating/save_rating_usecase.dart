// Executes the save rating use case.

import 'dart:io';
import 'package:dartz/dartz.dart';

import '../../../../../../core/error/failures.dart';
import '../../../repositories/rating_repository.dart';

/// Runs the save rating use case operation.
/// Handles saving a user rating with validation.
class SaveRatingUseCase {
  /// Repository instance for data operations.
  final RatingRepository repository;

  /// Runs the save rating use case operation.
  SaveRatingUseCase(this.repository);

  /// Validates input and delegates the save rating request to the repository.
  ///
  /// [userId] is the ID of the user submitting the rating.
  /// [stars] is the star rating (1-5).
  /// [comment] is the user's comment.
  /// [imageFile] is an optional image attachment.
  /// [existingImageUrl] is the existing image URL for updates.
  /// Returns either a failure or void on success.
  Future<Either<Failure, void>> execute({
    required String userId,
    required int stars,
    required String comment,
    File? imageFile,
    String? existingImageUrl,
  }) async {
    // Validate the user ID.
    if (userId.isEmpty) {
      return Left(ValidationFailure(message: 'User ID cannot be empty'));
    }

    // Validate the star rating.
    if (stars < 1 || stars > 5) {
      return Left(ValidationFailure(message: 'Stars must be between 1 and 5'));
    }

    // Delegate to repository to save the rating.
    return await repository.saveRating(
      userId: userId,
      stars: stars,
      comment: comment,
      imageFile: imageFile,
      existingImageUrl: existingImageUrl,
    );
  }
}