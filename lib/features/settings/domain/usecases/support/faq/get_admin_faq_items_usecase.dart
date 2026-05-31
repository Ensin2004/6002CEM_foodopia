// Executes the get admin faq items use case.

import 'package:dartz/dartz.dart';
import '../../../../../../core/error/failures.dart';
import '../../../entities/faq_item.dart';
import '../../../repositories/faq_repository.dart';

/// Loads data for the get admin faq items use case operation.
class GetAdminFaqItemsUseCase {
  final FaqRepository repository;

  /// Loads data for the get admin faq items use case operation.
  GetAdminFaqItemsUseCase(this.repository);

  /// Validates input and delegates the get admin faq items request to the repository.
  Future<Either<Failure, List<FaqItem>>> execute() async {
    return await repository.getAdminFaqItems();
  }

  Stream<Either<Failure, List<FaqItem>>> watch() {
    return repository.watchAdminFaqItems();
  }
}
