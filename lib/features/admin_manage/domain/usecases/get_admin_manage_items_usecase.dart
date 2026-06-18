import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_manage_item.dart';
import '../repositories/admin_manage_repository.dart';

/// Use case for retrieving admin-managed items.
/// Encapsulates the business logic for fetching items by category.
class GetAdminManageItemsUseCase {
  /// Repository instance for data operations.
  final AdminManageRepository repository;

  /// Creates a new get admin manage items use case instance.
  GetAdminManageItemsUseCase(this.repository);

  /// Executes the use case with the given category ID.
  ///
  /// [categoryId] is the ID of the category.
  /// Returns either a failure or a list of items on success.
  Future<Either<Failure, List<AdminManageItem>>> execute(
      String categoryId,
      ) async {
    // Delegate to repository to get items.
    return repository.getItems(categoryId);
  }
}