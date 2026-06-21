import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../repositories/about_repository.dart';

/// Use case for deleting about content.
/// Encapsulates the business logic for deleting about content documents.
class DeleteAboutContentUseCase {
  /// Repository instance for data operations.
  final AboutRepository repository;

  /// Creates a new delete about content use case instance.
  DeleteAboutContentUseCase(this.repository);

  /// Executes the use case with the given document ID.
  ///
  /// [documentId] is the ID of the document to delete.
  /// Returns either a failure or void on success.
  Future<Either<Failure, void>> execute(String documentId) async {
    // Validate the document ID.
    if (documentId.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Document ID cannot be empty'));
    }

    // Delegate to repository to delete the content.
    return repository.deleteAboutContent(documentId.trim());
  }
}