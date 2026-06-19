// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_statistics.dart';
import '../repositories/statistics_repository.dart';

// Handles GetAdminMealAnalyticStatisticsUseCase for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class GetAdminMealAnalyticStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetAdminMealAnalyticStatisticsUseCase(this._repository);

  // Handles execute for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Future<Either<Failure, AdminMealAnalyticStatistics>> execute({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getAdminMealAnalytic(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
