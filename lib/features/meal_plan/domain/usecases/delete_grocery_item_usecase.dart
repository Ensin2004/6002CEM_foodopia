import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/meal_plan_repository.dart';

/// Use case for deleting an item from a grocery list.
/// Encapsulates the business logic for grocery item deletion.
class DeleteGroceryItemUseCase {
  /// Repository instance for data operations.
  final MealPlanRepository repository;

  /// Creates a new delete grocery item use case instance.
  const DeleteGroceryItemUseCase(this.repository);

  /// Executes the use case with the given parameters.
  ///
  /// [listId] is the ID of the grocery list containing the item.
  /// [itemId] is the ID of the item to delete.
  /// Returns either a failure or void on success.
  Future<Either<Failure, void>> execute({
    required String listId,
    required String itemId,
  }) {
    // Delegate to repository to delete the item.
    return repository.deleteGroceryItem(listId: listId, itemId: itemId);
  }
}