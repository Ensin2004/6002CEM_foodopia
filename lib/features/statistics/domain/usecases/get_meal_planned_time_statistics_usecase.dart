import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/meal_planned_time_statistics.dart';
import '../repositories/statistics_repository.dart';

class GetMealPlannedTimeStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetMealPlannedTimeStatisticsUseCase(this._repository);

  Future<Either<Failure, MealPlannedTimeStatistics>> execute({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getMealPlannedTime(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
