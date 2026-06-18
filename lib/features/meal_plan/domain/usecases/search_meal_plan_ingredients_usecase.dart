import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/meal_plan_inspiration_input.dart';
import '../repositories/meal_plan_repository.dart';

/// Use case for searching inspiration ingredients.
/// Encapsulates the business logic for searching ingredients.
class SearchMealPlanIngredientsUseCase {
  /// Repository instance for data operations.
  final MealPlanRepository repository;

  /// Creates a new search ingredients use case instance.
  const SearchMealPlanIngredientsUseCase(this.repository);

  /// Executes the use case with the given search query.
  ///
  /// [query] is the search string to match against ingredient names.
  /// Returns either a failure or a list of matching ingredients on success.
  Future<Either<Failure, List<MealPlanInspirationIngredient>>> execute(
      String query,
      ) {
    // Delegate to repository to search for ingredients.
    return repository.searchInspirationIngredients(query);
  }
}