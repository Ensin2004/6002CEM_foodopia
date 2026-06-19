// Executes the get admin faq items use case.

import 'package:dartz/dartz.dart';
import '../../../../../../core/error/failures.dart';
import '../../../entities/faq_item.dart';
import '../../../repositories/faq_repository.dart';

/// Loads data for the get admin faq items use case operation.
/// Handles fetching all FAQ items for admin view.
class GetAdminFaqItemsUseCase {
  /// Repository instance for data operations.
  final FaqRepository repository;

  /// Loads data for the get admin faq items use case operation.
  GetAdminFaqItemsUseCase(this.repository);

  /// Validates input and delegates the get admin faq items request to the repository.
  ///
  /// Returns either a failure or a list of FAQ items on success.
  Future<Either<Failure, List<FaqItem>>> execute() async {
    return await repository.getAdminFaqItems();
  }

  /// Streams real-time updates for admin FAQ items.
  ///
  /// Returns a stream of either failures or lists of FAQ items.
  Stream<Either<Failure, List<FaqItem>>> watch() {
    return repository.watchAdminFaqItems();
  }
}