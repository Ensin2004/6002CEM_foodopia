// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_statistics.dart';
import '../repositories/statistics_repository.dart';

// Handles GetAdminUserUsageStatisticsUseCase for this part of the statistics page.
class GetAdminUserUsageStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetAdminUserUsageStatisticsUseCase(this._repository);

  // Handles execute for this part of the statistics page.
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
