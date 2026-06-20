// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/calories_posted_statistics.dart';
import '../repositories/statistics_repository.dart';

// Handles GetCaloriesPostedStatisticsUseCase for this part of the statistics page.
class GetCaloriesPostedStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetCaloriesPostedStatisticsUseCase(this._repository);

  // Handles execute for this part of the statistics page.
  Future<Either<Failure, CaloriesPostedStatistics>> execute({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getCaloriesPosted(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
