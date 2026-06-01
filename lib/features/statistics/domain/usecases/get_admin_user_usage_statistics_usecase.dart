import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_statistics.dart';
import '../repositories/statistics_repository.dart';

class GetAdminUserUsageStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetAdminUserUsageStatisticsUseCase(this._repository);

  Future<Either<Failure, AdminUserUsageStatistics>> execute({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getAdminUserUsage(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
