import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/meal_plan_dashboard.dart';

abstract class MealPlanRepository {
  Future<Either<Failure, MealPlanDashboard>> getDashboard();
  Future<Either<Failure, MealPlanWeather>> getTodayWeather();
}
