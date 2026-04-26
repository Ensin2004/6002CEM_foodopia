import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/help_center_repository.dart';

class SubmitIssueUseCase {
  final HelpCenterRepository repository;

  SubmitIssueUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String uid,
    required String message,
    File? imageFile,
  }) async {
    if (uid.isEmpty) {
      return Left(ValidationFailure(message: 'User ID cannot be empty'));
    }
    if (message.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Message cannot be empty'));
    }
    return await repository.submitIssue(
      uid: uid,
      message: message.trim(),
      imageFile: imageFile,
    );
  }
}