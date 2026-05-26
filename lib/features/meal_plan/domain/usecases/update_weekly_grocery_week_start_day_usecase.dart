import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/meal_plan_repository.dart';

class UpdateWeeklyGroceryWeekStartDayUseCase {
  final MealPlanRepository repository;

  const UpdateWeeklyGroceryWeekStartDayUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String userId,
    required String weekStartDay,
  }) {
    return repository.updateWeeklyGroceryWeekStartDay(
      userId: userId,
      weekStartDay: weekStartDay,
    );
  }
}
