import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/meal_plan_dashboard.dart';
import '../repositories/meal_plan_repository.dart';

class GetMealPlanPreferencesUseCase {
  final MealPlanRepository repository;

  const GetMealPlanPreferencesUseCase(this.repository);

  Future<Either<Failure, MealPlanPreferenceSummary>> execute(String uid) {
    return repository.getPreferences(uid);
  }
}
