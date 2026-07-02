import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_statistics.dart';
import '../repositories/statistics_repository.dart';

// Handles GetAdminHubRatingStatisticsUseCase for this part of the statistics page.
class GetAdminHubRatingStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetAdminHubRatingStatisticsUseCase(this._repository);

  // Handles execute for this part of the statistics page.
  Future<Either<Failure, AdminHubRatingStatistics>> execute({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getAdminHubRating(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
