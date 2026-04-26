import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/rating_repository.dart';

class UploadRatingImageUseCase {
  final RatingRepository repository;

  UploadRatingImageUseCase(this.repository);

  Future<Either<Failure, String>> execute(File imageFile) async {
    if (!await imageFile.exists()) {
      return Left(ValidationFailure(message: 'Image file does not exist'));
    }
    return await repository.uploadRatingImage(imageFile);
  }
}