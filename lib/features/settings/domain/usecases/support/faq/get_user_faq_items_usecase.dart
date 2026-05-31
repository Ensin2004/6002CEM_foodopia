// Executes the get user faq items use case.

import 'package:dartz/dartz.dart';
import '../../../../../../core/error/failures.dart';
import '../../../entities/faq_item.dart';
import '../../../repositories/faq_repository.dart';

/// Loads data for the get user faq items use case operation.
class GetUserFaqItemsUseCase {
  final FaqRepository repository;

  /// Loads data for the get user faq items use case operation.
  GetUserFaqItemsUseCase(this.repository);

  /// Validates input and delegates the get user faq items request to the repository.
  Future<Either<Failure, List<FaqItem>>> execute() async {
    return await repository.getUserFaqItems();
  }

  Stream<Either<Failure, List<FaqItem>>> watch() {
    return repository.watchUserFaqItems();
  }
}
