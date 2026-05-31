// Executes the save about content use case.

import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../repositories/about_repository.dart';

/// Runs the save about content use case operation.
class SaveAboutContentUseCase {
  // Renamed from UpdateAboutContentUseCase
  final AboutRepository repository;

  /// Runs the save about content use case operation.
  SaveAboutContentUseCase(this.repository);

  /// Validates input and delegates the save about content request to the repository.
  Future<Either<Failure, void>> execute({
    required String documentId,
    required String content,
  }) async {
    if (documentId.isEmpty) {
      return Left(ValidationFailure(message: 'Document ID cannot be empty'));
    }
    if (content.length > 10000) {
      return Left(
        ValidationFailure(
          message: 'Content exceeds maximum length of 10000 characters',
        ),
      );
    }
    return await repository.saveAboutContent(documentId, content);
  }
}
