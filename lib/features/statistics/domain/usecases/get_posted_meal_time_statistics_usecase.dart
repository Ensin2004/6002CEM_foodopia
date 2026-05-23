import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/posted_meal_time_statistics.dart';
import '../repositories/statistics_repository.dart';

class GetPostedMealTimeStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetPostedMealTimeStatisticsUseCase(this._repository);

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
