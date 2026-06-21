// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/meal_plan_method_statistics.dart';
import '../repositories/statistics_repository.dart';

// Handles GetMealPlanMethodStatisticsUseCase for this part of the statistics page.
class GetMealPlanMethodStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetMealPlanMethodStatisticsUseCase(this._repository);

  // Handles execute for this part of the statistics page.
  Future<Either<Failure, MealPlanMethodStatistics>> execute({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getMealPlanMethods(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
