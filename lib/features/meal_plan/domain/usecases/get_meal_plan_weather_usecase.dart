import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/meal_plan_dashboard.dart';
import '../repositories/meal_plan_repository.dart';

class GetMealPlanWeatherUseCase {
  final MealPlanRepository repository;

  const GetMealPlanWeatherUseCase(this.repository);

  Future<Either<Failure, MealPlanWeather>> execute(DateTime date) {
    return repository.getWeatherForDate(date);
  }
}
