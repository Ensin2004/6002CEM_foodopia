import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_statistics.dart';
import '../repositories/statistics_repository.dart';

class GetAdminPostAnalyticStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetAdminPostAnalyticStatisticsUseCase(this._repository);

  Future<Either<Failure, AdminPostAnalyticStatistics>> execute({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getAdminPostAnalytic(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
