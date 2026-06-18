// Executes the submit issue use case.

import 'dart:io';
import 'package:dartz/dartz.dart';

import '../../../../../../core/error/failures.dart';
import '../../../repositories/help_center_repository.dart';

/// Runs the submit issue use case operation.
/// Handles submitting a new help center issue with validation.
class SubmitIssueUseCase {
  /// Repository instance for data operations.
  final HelpCenterRepository repository;

  /// Runs the submit issue use case operation.
  SubmitIssueUseCase(this.repository);

  /// Validates input and delegates the submit issue request to the repository.
  ///
  /// [uid] is the ID of the user submitting the issue.
  /// [message] is the issue description.
  /// [imageFile] is an optional image attachment.
  /// Returns either a failure or void on success.
  Future<Either<Failure, void>> execute({
    required String uid,
    required String message,
    File? imageFile,
  }) async {
    // Validate the user ID.
    if (uid.isEmpty) {
      return Left(ValidationFailure(message: 'User ID cannot be empty'));
    }

    // Validate the message.
    if (message.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Message cannot be empty'));
    }

    // Delegate to repository to submit the issue.
    return await repository.submitIssue(
      uid: uid,
      message: message.trim(),
      imageFile: imageFile,
    );
  }
}