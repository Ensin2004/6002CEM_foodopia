// Executes the save about content use case.

import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../repositories/about_repository.dart';

/// Runs the save about content use case operation.
/// Handles saving about content with validation.
class SaveAboutContentUseCase {
  // Renamed from UpdateAboutContentUseCase.
  /// Repository instance for data operations.
  final AboutRepository repository;

  /// Runs the save about content use case operation.
  SaveAboutContentUseCase(this.repository);

  /// Validates input and delegates the save about content request to the repository.
  ///
  /// [documentId] is the ID of the document to save.
  /// [content] is the content to save.
  /// Returns either a failure or void on success.
  Future<Either<Failure, void>> execute({
    required String documentId,
    required String content,
  }) async {
    // Validate the document ID.
    if (documentId.isEmpty) {
      return Left(ValidationFailure(message: 'Document ID cannot be empty'));
    }

    // Validate content length.
    if (content.length > 10000) {
      return Left(
        ValidationFailure(
          message: 'Content exceeds maximum length of 10000 characters',
        ),
      );
    }

    // Delegate to repository to save the content.
    return await repository.saveAboutContent(documentId, content);
  }
}