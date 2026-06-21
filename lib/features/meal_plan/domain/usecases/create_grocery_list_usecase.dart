import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_grocery_list_plan.dart';
import '../repositories/meal_plan_repository.dart';

/// Use case for creating a new grocery list.
/// Encapsulates the business logic for grocery list creation.
class CreateGroceryListUseCase {
  /// Repository instance for data operations.
  final MealPlanRepository repository;

  /// Creates a new create grocery list use case instance.
  const CreateGroceryListUseCase(this.repository);

  /// Executes the use case with the given request.
  ///
  /// [request] contains the grocery list creation parameters.
  /// Returns either a failure or the new list ID on success.
  Future<Either<Failure, String>> execute(CreateGroceryListRequest request) {
    // Delegate to repository to create the list.
    return repository.createGroceryList(request);
  }
}