import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/about_content.dart';
import '../repositories/about_repository.dart';

class GetAboutContentUseCase {
  final AboutRepository repository;

  GetAboutContentUseCase(this.repository);

  Future<Either<Failure, AboutContent>> execute(String documentId) async {
    if (documentId.isEmpty) {
      return Left(ValidationFailure(message: 'Document ID cannot be empty'));
    }
    return await repository.getAboutContent(documentId);
  }
}