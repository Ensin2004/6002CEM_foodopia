import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/manage_grocery_list_detail.dart';
import '../repositories/meal_plan_repository.dart';

/// Use case for adding an item to a grocery list.
/// Encapsulates the business logic for adding grocery items.
class AddGroceryItemUseCase {
  /// Repository instance for data operations.
  final MealPlanRepository repository;

  /// Creates a new add grocery item use case instance.
  const AddGroceryItemUseCase(this.repository);

  /// Executes the use case with the given request.
  ///
  /// [request] contains the grocery item details to add.
  /// Returns either a failure or void on success.
  Future<Either<Failure, void>> execute(AddGroceryItemRequest request) {
    // Delegate to repository to add the item.
    return repository.addGroceryItem(request);
  }
}