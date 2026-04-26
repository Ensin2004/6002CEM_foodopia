import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/faq_repository.dart';

class UploadFaqImageUseCase {
  final FaqRepository repository;

  UploadFaqImageUseCase(this.repository);

  Future<Either<Failure, String>> execute(File imageFile) async {
    if (!await imageFile.exists()) {
      return Left(ValidationFailure(message: 'Image file does not exist'));
    }
    return await repository.uploadFaqImage(imageFile);
  }
}