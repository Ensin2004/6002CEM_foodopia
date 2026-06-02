import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_statistics.dart';
import '../repositories/statistics_repository.dart';

class GetAdminUsageForecastStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetAdminUsageForecastStatisticsUseCase(this._repository);

  Future<Either<Failure, AdminUserUsageStatistics>> execute({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getAdminUsageForecast(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
