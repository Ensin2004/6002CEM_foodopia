// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/calories_intake_statistics.dart';
import '../repositories/statistics_repository.dart';

// Handles GetCaloriesIntakeStatisticsUseCase for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class GetCaloriesIntakeStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetCaloriesIntakeStatisticsUseCase(this._repository);

  // Handles execute for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Future<Either<Failure, CaloriesIntakeStatistics>> execute({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getCaloriesIntake(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
