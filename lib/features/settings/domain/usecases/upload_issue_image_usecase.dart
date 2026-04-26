import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/help_center_repository.dart';

class UploadIssueImageUseCase {
  final HelpCenterRepository repository;

  UploadIssueImageUseCase(this.repository);

  Future<Either<Failure, String>> execute(File imageFile) async {
    if (!await imageFile.exists()) {
      return Left(ValidationFailure(message: 'Image file does not exist'));
    }
    return await repository.uploadIssueImage(imageFile);
  }
}