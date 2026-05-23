import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/calories_posted_statistics.dart';
import '../repositories/statistics_repository.dart';

class GetCaloriesPostedStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetCaloriesPostedStatisticsUseCase(this._repository);

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
