import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_meal_ai_plan.dart';
import '../repositories/meal_plan_repository.dart';

class SaveAiMealPlanUseCase {
  final MealPlanRepository repository;

  const SaveAiMealPlanUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String userId,
    required DateTime date,
    required AddMealCategoryOption mealCategory,
    required List<AddMealAiRecipe> recipes,
    required AddMealAiGenerationRequest request,
  }) {
    return repository.saveAiMealPlans(
      userId: userId,
      date: date,
      mealCategory: mealCategory,
      recipes: recipes,
      request: request,
    );
  }
}
