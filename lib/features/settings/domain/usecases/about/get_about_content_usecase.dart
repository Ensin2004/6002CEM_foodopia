// Executes the get about content use case.

import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../entities/about_content.dart';
import '../../repositories/about_repository.dart';

/// Loads data for the get about content use case operation.
class GetAboutContentUseCase {
  final AboutRepository repository;

  /// Loads data for the get about content use case operation.
  GetAboutContentUseCase(this.repository);

  /// Validates input and delegates the get about content request to the repository.
  Future<Either<Failure, AboutContent>> execute(String documentId) async {
    if (documentId.isEmpty) {
      return Left(ValidationFailure(message: 'Document ID cannot be empty'));
    }
    return await repository.getAboutContent(documentId);
  }

  Stream<Either<Failure, AboutContent>> watch(String documentId) {
    return repository.watchAboutContent(documentId);
  }
}
