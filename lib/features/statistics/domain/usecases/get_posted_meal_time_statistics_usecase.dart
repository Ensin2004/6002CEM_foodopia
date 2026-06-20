// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/posted_meal_time_statistics.dart';
import '../repositories/statistics_repository.dart';

// Handles GetPostedMealTimeStatisticsUseCase for this part of the statistics page.
class GetPostedMealTimeStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetPostedMealTimeStatisticsUseCase(this._repository);

  // Handles execute for this part of the statistics page.
  Future<Either<Failure, PostedMealTimeStatistics>> execute({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getPostedMealTime(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
