import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_manage_item.dart';
import '../repositories/admin_manage_repository.dart';

/// Use case for reordering admin-managed items.
/// Encapsulates the business logic for reordering items.
class ReorderAdminManageItemsUseCase {
  /// Repository instance for data operations.
  final AdminManageRepository repository;

  /// Creates a new reorder admin manage items use case instance.
  ReorderAdminManageItemsUseCase(this.repository);

  /// Executes the use case with the given parameters.
  ///
  /// [categoryId] is the ID of the category.
  /// [items] is the list of items in the new order.
  /// Returns either a failure or void on success.
  Future<Either<Failure, void>> execute({
    required String categoryId,
    required List<AdminManageItem> items,
  }) {
    // Delegate to repository to reorder items.
    return repository.reorderItems(categoryId: categoryId, items: items);
  }
}