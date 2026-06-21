import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_manage_item.dart';
import '../repositories/admin_manage_repository.dart';

/// Use case for saving an admin-managed item.
/// Encapsulates the business logic for creating or updating items.
class SaveAdminManageItemUseCase {
  /// Repository instance for data operations.
  final AdminManageRepository repository;

  /// Creates a new save admin manage item use case instance.
  SaveAdminManageItemUseCase(this.repository);

  /// Executes the use case with the given parameters.
  ///
  /// [categoryId] is the ID of the category.
  /// [item] is the item to save.
  /// Returns either a failure or void on success.
  Future<Either<Failure, void>> execute({
    required String categoryId,
    required AdminManageItem item,
  }) async {
    // Delegate to repository to save the item.
    return repository.saveItem(categoryId: categoryId, item: item);
  }
}