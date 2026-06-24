import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/cooking_time_statistics.dart';
import '../repositories/statistics_repository.dart';

// Handles GetCookingTimeStatisticsUseCase for this part of the statistics page.
class GetCookingTimeStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetCookingTimeStatisticsUseCase(this._repository);

  // Handles execute for this part of the statistics page.
  Future<Either<Failure, CookingTimeStatistics>> execute({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getCookingTime(startDate: startDate, endDate: endDate);
  }
}
