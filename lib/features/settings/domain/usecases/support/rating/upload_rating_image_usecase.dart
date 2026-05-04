// Executes the upload rating image use case.

import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../../../core/error/failures.dart';
import '../../../repositories/rating_repository.dart';

/// Runs the upload rating image use case operation.
class UploadRatingImageUseCase {
  final RatingRepository repository;

  /// Runs the upload rating image use case operation.
  UploadRatingImageUseCase(this.repository);

  /// Validates input and delegates the upload rating image request to the repository.
  Future<Either<Failure, String>> execute(File imageFile) async {
    if (!await imageFile.exists()) {
      return Left(ValidationFailure(message: 'Image file does not exist'));
    }
    return await repository.uploadRatingImage(imageFile);
  }
}
