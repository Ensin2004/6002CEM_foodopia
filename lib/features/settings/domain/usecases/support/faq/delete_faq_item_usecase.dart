// Executes the delete faq item use case.

import 'package:dartz/dartz.dart';
import '../../../../../../core/error/failures.dart';
import '../../../repositories/faq_repository.dart';

/// Runs the delete faq item use case operation.
/// Handles deleting an FAQ item with validation.
class DeleteFaqItemUseCase {
  /// Repository instance for data operations.
  final FaqRepository repository;

  /// Runs the delete faq item use case operation.
  DeleteFaqItemUseCase(this.repository);

  /// Validates input and delegates the delete faq item request to the repository.
  ///
  /// [id] is the ID of the FAQ item to delete.
  /// Returns either a failure or void on success.
  Future<Either<Failure, void>> execute(String id) async {
    // Validate the ID.
    if (id.isEmpty) {
      return Left(ValidationFailure(message: 'ID cannot be empty'));
    }

    // Delegate to repository to delete the item.
    return await repository.deleteFaqItem(id);
  }
}