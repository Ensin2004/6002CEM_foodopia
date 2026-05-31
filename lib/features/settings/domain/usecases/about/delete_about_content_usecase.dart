import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../repositories/about_repository.dart';

class DeleteAboutContentUseCase {
  final AboutRepository repository;

  DeleteAboutContentUseCase(this.repository);

  Future<Either<Failure, void>> execute(String documentId) async {
    if (documentId.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Document ID cannot be empty'));
    }
    return repository.deleteAboutContent(documentId.trim());
  }
}
