import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/meal_plan_inspiration_input.dart';
import '../repositories/meal_plan_repository.dart';

class GetMealPlanDefaultIngredientsUseCase {
  final MealPlanRepository repository;

  const GetMealPlanDefaultIngredientsUseCase(this.repository);

  Future<Either<Failure, List<MealPlanInspirationIngredient>>> execute() {
    return repository.getDefaultInspirationIngredients();
  }
}
