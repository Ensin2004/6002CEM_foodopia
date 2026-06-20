// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/post_analytic_statistics.dart';
import '../repositories/statistics_repository.dart';

// Handles GetPostAnalyticStatisticsUseCase for this part of the statistics page.
class GetPostAnalyticStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetPostAnalyticStatisticsUseCase(this._repository);

  // Handles execute for this part of the statistics page.
  Future<Either<Failure, PostAnalyticStatistics>> execute({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getPostAnalytic(startDate: startDate, endDate: endDate);
  }
}
