// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/calories_intake_statistics.dart';
import '../repositories/statistics_repository.dart';

// Handles GetAdminNutrientInsightStatisticsUseCase for this part of the statistics page.
class GetAdminNutrientInsightStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetAdminNutrientInsightStatisticsUseCase(this._repository);

  // Handles execute for this part of the statistics page.
  Future<Either<Failure, CaloriesIntakeStatistics>> execute({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getAdminNutrientInsight(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
