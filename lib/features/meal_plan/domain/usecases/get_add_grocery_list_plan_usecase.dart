import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_grocery_list_plan.dart';
import '../repositories/meal_plan_repository.dart';

/// Use case for retrieving the grocery list plan creation data.
/// Encapsulates the business logic for fetching grocery list plan data.
class GetAddGroceryListPlanUseCase {
  /// Repository instance for data operations.
  final MealPlanRepository repository;

  /// Creates a new get grocery list plan use case instance.
  const GetAddGroceryListPlanUseCase(this.repository);

  /// Executes the use case with the given user ID.
  ///
  /// [userId] is the ID of the user requesting the plan.
  /// Returns either a failure or the grocery list plan on success.
  Future<Either<Failure, AddGroceryListPlan>> execute(String userId) {
    // Delegate to repository to retrieve the plan.
    return repository.getAddGroceryListPlan(userId);
  }
}