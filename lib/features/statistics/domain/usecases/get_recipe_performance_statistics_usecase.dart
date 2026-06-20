// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/recipe_performance_statistics.dart';
import '../repositories/statistics_repository.dart';

// Handles GetRecipePerformanceStatisticsUseCase for this part of the statistics page.
class GetRecipePerformanceStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetRecipePerformanceStatisticsUseCase(this._repository);

  // Handles execute for this part of the statistics page.
  Future<Either<Failure, RecipePerformanceStatistics>> execute() {
    return _repository.getRecipePerformance();
  }
}
