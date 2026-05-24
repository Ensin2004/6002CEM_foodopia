import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/recipe_performance_statistics.dart';
import '../repositories/statistics_repository.dart';

class GetRecipePerformanceStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetRecipePerformanceStatisticsUseCase(this._repository);

  Future<Either<Failure, RecipePerformanceStatistics>> execute() {
    return _repository.getRecipePerformance();
  }
}
