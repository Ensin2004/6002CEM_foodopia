import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/rating_repository.dart';

class SaveRatingUseCase {
  final RatingRepository repository;

  SaveRatingUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String userId,
    required int stars,
    required String comment,
    File? imageFile,
    String? existingImageUrl,
  }) async {
    if (userId.isEmpty) {
      return Left(ValidationFailure(message: 'User ID cannot be empty'));
    }
    if (stars < 1 || stars > 5) {
      return Left(ValidationFailure(message: 'Stars must be between 1 and 5'));
    }
    return await repository.saveRating(
      userId: userId,
      stars: stars,
      comment: comment,
      imageFile: imageFile,
      existingImageUrl: existingImageUrl,
    );
  }
}