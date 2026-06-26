import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_statistics.dart';
import '../repositories/statistics_repository.dart';

// Handles GetAdminModerationStatisticsUseCase for this part of the statistics page.
class GetAdminModerationStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetAdminModerationStatisticsUseCase(this._repository);

  Future<Either<Failure, AdminModerationStatistics>> execute({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getAdminModeration(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
