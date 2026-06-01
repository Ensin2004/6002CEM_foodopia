import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/cooking_time_statistics.dart';
import '../repositories/statistics_repository.dart';

class GetCookingTimeStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetCookingTimeStatisticsUseCase(this._repository);

  Future<Either<Failure, CookingTimeStatistics>> execute({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getCookingTime(startDate: startDate, endDate: endDate);
  }
}
