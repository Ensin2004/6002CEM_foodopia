// Executes the delete faq item use case.

import 'package:dartz/dartz.dart';
import '../../../../../../core/error/failures.dart';
import '../../../repositories/faq_repository.dart';

/// Runs the delete faq item use case operation.
class DeleteFaqItemUseCase {
  final FaqRepository repository;

  /// Runs the delete faq item use case operation.
  DeleteFaqItemUseCase(this.repository);

  /// Validates input and delegates the delete faq item request to the repository.
  Future<Either<Failure, void>> execute(String id) async {
    if (id.isEmpty) {
      return Left(ValidationFailure(message: 'ID cannot be empty'));
    }
    return await repository.deleteFaqItem(id);
  }
}
