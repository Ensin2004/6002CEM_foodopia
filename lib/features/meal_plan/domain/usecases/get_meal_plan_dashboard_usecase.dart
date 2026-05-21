import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/meal_plan_dashboard.dart';
import '../repositories/meal_plan_repository.dart';

class GetMealPlanDashboardUseCase {
  final MealPlanRepository repository;

  const GetMealPlanDashboardUseCase(this.repository);

  Future<Either<Failure, MealPlanDashboard>> execute() {
    return repository.getDashboard();
  }
}
