import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/meal_plan_inspiration_input.dart';
import '../repositories/meal_plan_repository.dart';

class SearchMealPlanIngredientsUseCase {
  final MealPlanRepository repository;

  const SearchMealPlanIngredientsUseCase(this.repository);

  Future<Either<Failure, List<MealPlanInspirationIngredient>>> execute(
    String query,
  ) {
    return repository.searchInspirationIngredients(query);
  }
}
