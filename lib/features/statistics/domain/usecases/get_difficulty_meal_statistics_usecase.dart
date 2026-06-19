// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/difficulty_meal_statistics.dart';
import '../repositories/statistics_repository.dart';

// Handles GetDifficultyMealStatisticsUseCase for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class GetDifficultyMealStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetDifficultyMealStatisticsUseCase(this._repository);

  // Handles execute for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Future<Either<Failure, DifficultyMealStatistics>> execute({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getDifficultyMeals(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
