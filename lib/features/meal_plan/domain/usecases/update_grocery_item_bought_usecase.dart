import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/meal_plan_repository.dart';

/// Use case for updating the bought status of a grocery item.
/// Encapsulates the business logic for toggling item purchase status.
class UpdateGroceryItemBoughtUseCase {
  /// Repository instance for data operations.
  final MealPlanRepository repository;

  /// Creates a new update grocery item bought status use case instance.
  const UpdateGroceryItemBoughtUseCase(this.repository);

  /// Executes the use case with the given parameters.
  ///
  /// [listId] is the ID of the grocery list containing the item.
  /// [itemId] is the ID of the item to update.
  /// [bought] is the new bought status (true for bought, false for not bought).
  /// Returns either a failure or void on success.
  Future<Either<Failure, void>> execute({
    required String listId,
    required String itemId,
    required bool bought,
  }) {
    // Delegate to repository to update the item status.
    return repository.updateGroceryItemBought(
      listId: listId,
      itemId: itemId,
      bought: bought,
    );
  }
}