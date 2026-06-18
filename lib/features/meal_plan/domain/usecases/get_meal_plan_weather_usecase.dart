import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/meal_plan_dashboard.dart';
import '../repositories/meal_plan_repository.dart';

/// Use case for retrieving weather information.
/// Encapsulates the business logic for fetching weather data.
class GetMealPlanWeatherUseCase {
  /// Repository instance for data operations.
  final MealPlanRepository repository;

  /// Creates a new get meal plan weather use case instance.
  const GetMealPlanWeatherUseCase(this.repository);

  /// Executes the use case with the given date.
  ///
  /// [date] is the date to get weather information for.
  /// Returns either a failure or the weather data on success.
  Future<Either<Failure, MealPlanWeather>> execute(DateTime date) {
    // Delegate to repository to retrieve weather data.
    return repository.getWeatherForDate(date);
  }
}