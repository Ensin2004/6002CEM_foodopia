import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_meal_ai_plan.dart';
import '../repositories/meal_plan_repository.dart';

class SaveRecipeMealPlanUseCase {
  final MealPlanRepository repository;

  const SaveRecipeMealPlanUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String userId,
    required DateTime date,
    required AddMealCategoryOption mealCategory,
    required AddMealAiRecipe recipe,
    required String source,
    required int servingCount,
  }) {
    return repository.saveRecipeMealPlan(
      userId: userId,
      date: date,
      mealCategory: mealCategory,
      recipe: recipe,
      source: source,
      servingCount: servingCount,
    );
  }
}
