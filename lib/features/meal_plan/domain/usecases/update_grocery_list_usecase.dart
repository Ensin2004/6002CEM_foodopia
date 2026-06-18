import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/meal_plan_repository.dart';

/// Use case for updating a grocery list's details.
/// Encapsulates the business logic for modifying grocery list information.
class UpdateGroceryListUseCase {
  /// Repository instance for data operations.
  final MealPlanRepository repository;

  /// Creates a new update grocery list use case instance.
  const UpdateGroceryListUseCase(this.repository);

  /// Executes the use case with the given parameters.
  ///
  /// [listId] is the ID of the grocery list to update.
  /// [name] is the new display title for the list.
  /// [startDate] is the new start date for the list.
  /// [endDate] is the new end date for the list.
  /// Returns either a failure or void on success.
  Future<Either<Failure, void>> execute({
    required String listId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    // Delegate to repository to update the grocery list.
    return repository.updateGroceryList(
      listId: listId,
      name: name,
      startDate: startDate,
      endDate: endDate,
    );
  }
}