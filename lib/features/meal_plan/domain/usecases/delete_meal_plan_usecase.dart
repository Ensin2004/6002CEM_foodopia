import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/meal_plan_repository.dart';

class DeleteMealPlanUseCase {
  final MealPlanRepository repository;

  const DeleteMealPlanUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String userId,
    required String mealPlanId,
  }) {
    return repository.deleteMealPlan(userId: userId, mealPlanId: mealPlanId);
  }
}
