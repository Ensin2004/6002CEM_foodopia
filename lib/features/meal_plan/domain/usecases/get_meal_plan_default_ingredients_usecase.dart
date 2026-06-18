import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/meal_plan_inspiration_input.dart';
import '../repositories/meal_plan_repository.dart';

/// Use case for retrieving default inspiration ingredients.
/// Encapsulates the business logic for fetching default ingredients.
class GetMealPlanDefaultIngredientsUseCase {
  /// Repository instance for data operations.
  final MealPlanRepository repository;

  /// Creates a new get default ingredients use case instance.
  const GetMealPlanDefaultIngredientsUseCase(this.repository);

  /// Executes the use case.
  ///
  /// Returns either a failure or a list of default inspiration ingredients on success.
  Future<Either<Failure, List<MealPlanInspirationIngredient>>> execute() {
    // Delegate to repository to retrieve default ingredients.
    return repository.getDefaultInspirationIngredients();
  }
}