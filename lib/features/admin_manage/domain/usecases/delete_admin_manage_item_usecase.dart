import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/admin_manage_repository.dart';

/// Use case for deleting an admin-managed item.
/// Encapsulates the business logic for deleting items.
class DeleteAdminManageItemUseCase {
  /// Repository instance for data operations.
  final AdminManageRepository repository;

  /// Creates a new delete admin manage item use case instance.
  DeleteAdminManageItemUseCase(this.repository);

  /// Executes the use case with the given parameters.
  ///
  /// [categoryId] is the ID of the category containing the item.
  /// [id] is the ID of the item to delete.
  /// Returns either a failure or void on success.
  Future<Either<Failure, void>> execute({
    required String categoryId,
    required String id,
  }) async {
    // Delegate to repository to delete the item.
    return repository.deleteItem(categoryId: categoryId, id: id);
  }
}