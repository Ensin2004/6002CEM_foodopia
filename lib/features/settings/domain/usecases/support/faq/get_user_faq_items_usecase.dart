// Executes the get user faq items use case.

import 'package:dartz/dartz.dart';
import '../../../../../../core/error/failures.dart';
import '../../../entities/faq_item.dart';
import '../../../repositories/faq_repository.dart';

/// Loads data for the get user faq items use case operation.
/// Handles fetching all FAQ items for user view.
class GetUserFaqItemsUseCase {
  /// Repository instance for data operations.
  final FaqRepository repository;

  /// Loads data for the get user faq items use case operation.
  GetUserFaqItemsUseCase(this.repository);

  /// Validates input and delegates the get user faq items request to the repository.
  ///
  /// Returns either a failure or a list of FAQ items on success.
  Future<Either<Failure, List<FaqItem>>> execute() async {
    return await repository.getUserFaqItems();
  }

  /// Streams real-time updates for user FAQ items.
  ///
  /// Returns a stream of either failures or lists of FAQ items.
  Stream<Either<Failure, List<FaqItem>>> watch() {
    return repository.watchUserFaqItems();
  }
}