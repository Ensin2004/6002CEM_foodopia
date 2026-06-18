import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_meal_ai_plan.dart';
import '../repositories/meal_plan_repository.dart';

/// Use case for retrieving the AI meal plan creation data.
/// Encapsulates the business logic for fetching AI meal plan data.
class GetAddMealAiPlanUseCase {
  /// Repository instance for data operations.
  final MealPlanRepository repository;

  /// Creates a new get AI meal plan use case instance.
  const GetAddMealAiPlanUseCase(this.repository);

  /// Executes the use case with the given parameters.
  ///
  /// [userId] is the ID of the user requesting the plan.
  /// [mealType] is the type of meal to plan for.
  /// Returns either a failure or the AI meal plan on success.
  Future<Either<Failure, AddMealAiPlan>> execute({
    required String userId,
    required String mealType,
  }) {
    // Delegate to repository to retrieve the meal plan.
    return repository.getAddMealAiPlan(userId: userId, mealType: mealType);
  }
}