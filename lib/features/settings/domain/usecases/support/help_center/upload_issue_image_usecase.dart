// Executes the upload issue image use case.

import 'dart:io';
import 'package:dartz/dartz.dart';

import '../../../../../../core/error/failures.dart';
import '../../../repositories/help_center_repository.dart';

/// Runs the upload issue image use case operation.
class UploadIssueImageUseCase {
  final HelpCenterRepository repository;

  /// Runs the upload issue image use case operation.
  UploadIssueImageUseCase(this.repository);

  /// Validates input and delegates the upload issue image request to the repository.
  Future<Either<Failure, String>> execute(File imageFile) async {
    if (!await imageFile.exists()) {
      return Left(ValidationFailure(message: 'Image file does not exist'));
    }
    return await repository.uploadIssueImage(imageFile);
  }
}
