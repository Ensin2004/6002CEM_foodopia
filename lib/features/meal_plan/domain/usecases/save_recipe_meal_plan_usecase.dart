import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_meal_ai_plan.dart';
import '../repositories/meal_plan_repository.dart';

/// Use case for saving a recipe as a meal plan.
/// Encapsulates the business logic for persisting a recipe meal plan.
class SaveRecipeMealPlanUseCase {
  /// Repository instance for data operations.
  final MealPlanRepository repository;

  /// Creates a new save recipe meal plan use case instance.
  const SaveRecipeMealPlanUseCase(this.repository);

  /// Executes the use case with the given parameters.
  ///
  /// [userId] is the ID of the user saving the meal plan.
  /// [date] is the date for the meal plan.
  /// [mealCategory] is the category of the meal.
  /// [recipe] is the recipe to save as a meal plan.
  /// [source] is the source of the recipe.
  /// [servingCount] is the number of servings for the meal.
  /// Returns either a failure or void on success.
  Future<Either<Failure, void>> execute({
    required String userId,
    required DateTime date,
    required AddMealCategoryOption mealCategory,
    required AddMealAiRecipe recipe,
    required String source,
    required int servingCount,
  }) {
    // Delegate to repository to save the recipe meal plan.
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