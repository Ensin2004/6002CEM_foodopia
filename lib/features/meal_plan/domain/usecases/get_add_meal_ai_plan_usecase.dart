import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_meal_ai_plan.dart';
import '../repositories/meal_plan_repository.dart';

class GetAddMealAiPlanUseCase {
  final MealPlanRepository repository;

  const GetAddMealAiPlanUseCase(this.repository);

  Future<Either<Failure, AddMealAiPlan>> execute({
    required String userId,
    required String mealType,
  }) {
    return repository.getAddMealAiPlan(userId: userId, mealType: mealType);
  }
}
