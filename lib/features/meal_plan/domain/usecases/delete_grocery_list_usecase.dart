import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/meal_plan_repository.dart';

/// Use case for deleting a grocery list.
class DeleteGroceryListUseCase {
  /// Repository instance for data operations.
  final MealPlanRepository repository;

  /// Creates a new delete grocery list use case instance.
  const DeleteGroceryListUseCase(this.repository);

  /// Executes the use case.
  Future<Either<Failure, void>> execute(String listId) {
    return repository.deleteGroceryList(listId);
  }
}
