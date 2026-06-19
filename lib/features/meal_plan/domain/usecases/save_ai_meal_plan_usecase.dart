import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_meal_ai_plan.dart';
import '../repositories/meal_plan_repository.dart';

/// Use case for saving AI-generated meal plans.
/// Encapsulates the business logic for persisting AI meal plans.
class SaveAiMealPlanUseCase {
  /// Repository instance for data operations.
  final MealPlanRepository repository;

  /// Creates a new save AI meal plan use case instance.
  const SaveAiMealPlanUseCase(this.repository);

  /// Executes the use case with the given parameters.
  ///
  /// [userId] is the ID of the user saving the meal plans.
  /// [date] is the date for the meal plans.
  /// [mealCategory] is the category of the meals.
  /// [recipes] is the list of AI-generated recipes to save.
  /// [request] is the original generation request data.
  /// Returns either a failure or void on success.
  Future<Either<Failure, void>> execute({
    required String userId,
    required DateTime date,
    required AddMealCategoryOption mealCategory,
    required List<AddMealAiRecipe> recipes,
    required AddMealAiGenerationRequest request,
  }) {
    // Delegate to repository to save AI meal plans.
    return repository.saveAiMealPlans(
      userId: userId,
      date: date,
      mealCategory: mealCategory,
      recipes: recipes,
      request: request,
    );
  }
}