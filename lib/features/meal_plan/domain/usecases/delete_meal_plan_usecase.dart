import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/meal_plan_repository.dart';

/// Use case for deleting a meal plan.
/// Encapsulates the business logic for meal plan deletion.
class DeleteMealPlanUseCase {
  /// Repository instance for data operations.
  final MealPlanRepository repository;

  /// Creates a new delete meal plan use case instance.
  const DeleteMealPlanUseCase(this.repository);

  /// Executes the use case with the given parameters.
  ///
  /// [userId] is the ID of the user who owns the meal plan.
  /// [mealPlanId] is the ID of the meal plan to delete.
  /// Returns either a failure or void on success.
  Future<Either<Failure, void>> execute({
    required String userId,
    required String mealPlanId,
  }) {
    // Delegate to repository to delete the meal plan.
    return repository.deleteMealPlan(userId: userId, mealPlanId: mealPlanId);
  }
}