import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/post_analytic_statistics.dart';
import '../repositories/statistics_repository.dart';

class GetPostAnalyticStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetPostAnalyticStatisticsUseCase(this._repository);

  Future<Either<Failure, PostAnalyticStatistics>> execute({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getPostAnalytic(startDate: startDate, endDate: endDate);
  }
}
