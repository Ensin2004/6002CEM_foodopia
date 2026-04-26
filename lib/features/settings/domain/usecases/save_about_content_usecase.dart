import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/about_repository.dart';

class SaveAboutContentUseCase {  // Renamed from UpdateAboutContentUseCase
  final AboutRepository repository;

  SaveAboutContentUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String documentId,
    required String content,
  }) async {
    if (documentId.isEmpty) {
      return Left(ValidationFailure(message: 'Document ID cannot be empty'));
    }
    if (content.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Content cannot be empty'));
    }
    if (content.length > 10000) {
      return Left(ValidationFailure(message: 'Content exceeds maximum length of 10000 characters'));
    }
    return await repository.saveAboutContent(documentId, content);
  }
}