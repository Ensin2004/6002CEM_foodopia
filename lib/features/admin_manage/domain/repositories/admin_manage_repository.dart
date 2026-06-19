import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_manage_item.dart';

/// Repository contract for admin-managed option lists.
/// Defines data operations for configurable items.
abstract class AdminManageRepository {
  /// Retrieves items for a category.
  ///
  /// [categoryId] is the ID of the category.
  /// Returns either a failure or a list of items on success.
  Future<Either<Failure, List<AdminManageItem>>> getItems(String categoryId);

  /// Saves an item (creates or updates).
  ///
  /// [categoryId] is the ID of the category.
  /// [item] is the item to save.
  /// Returns either a failure or void on success.
  Future<Either<Failure, void>> saveItem({
    required String categoryId,
    required AdminManageItem item,
  });

  /// Deletes an item.
  ///
  /// [categoryId] is the ID of the category.
  /// [id] is the ID of the item to delete.
  /// Returns either a failure or void on success.
  Future<Either<Failure, void>> deleteItem({
    required String categoryId,
    required String id,
  });

  /// Reorders items.
  ///
  /// [categoryId] is the ID of the category.
  /// [items] is the list of items in the new order.
  /// Returns either a failure or void on success.
  Future<Either<Failure, void>> reorderItems({
    required String categoryId,
    required List<AdminManageItem> items,
  });
}