import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_statistics.dart';
import '../repositories/statistics_repository.dart';

// Handles GetAdminPostAnalyticStatisticsUseCase for this part of the statistics page.
class GetAdminPostAnalyticStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetAdminPostAnalyticStatisticsUseCase(this._repository);

  // Handles execute for this part of the statistics page.
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
