// Executes the upload faq image use case.

import 'dart:io';
import 'package:dartz/dartz.dart';

import '../../../../../../core/error/failures.dart';
import '../../../repositories/faq_repository.dart';

/// Runs the upload faq image use case operation.
class UploadFaqImageUseCase {
  final FaqRepository repository;

  /// Runs the upload faq image use case operation.
  UploadFaqImageUseCase(this.repository);

  /// Validates input and delegates the upload faq image request to the repository.
  Future<Either<Failure, String>> execute(File imageFile) async {
    if (!await imageFile.exists()) {
      return Left(ValidationFailure(message: 'Image file does not exist'));
    }
    return await repository.uploadFaqImage(imageFile);
  }
}
