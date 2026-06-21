// Executes the get about content use case.

import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../entities/about_content.dart';
import '../../repositories/about_repository.dart';

/// Loads data for the get about content use case operation.
/// Handles fetching about content with validation.
class GetAboutContentUseCase {
  /// Repository instance for data operations.
  final AboutRepository repository;

  /// Loads data for the get about content use case operation.
  GetAboutContentUseCase(this.repository);

  /// Validates input and delegates the get about content request to the repository.
  ///
  /// [documentId] is the ID of the document to retrieve.
  /// Returns either a failure or the about content on success.
  Future<Either<Failure, AboutContent>> execute(String documentId) async {
    // Validate the document ID.
    if (documentId.isEmpty) {
      return Left(ValidationFailure(message: 'Document ID cannot be empty'));
    }

    // Delegate to repository to get the content.
    return await repository.getAboutContent(documentId);
  }

  /// Streams real-time updates for about content.
  ///
  /// [documentId] is the ID of the document to watch.
  /// Returns a stream of either failures or about content.
  Stream<Either<Failure, AboutContent>> watch(String documentId) {
    return repository.watchAboutContent(documentId);
  }
}