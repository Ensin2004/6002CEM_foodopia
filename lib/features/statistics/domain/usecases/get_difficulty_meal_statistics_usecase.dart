import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/difficulty_meal_statistics.dart';
import '../repositories/statistics_repository.dart';

class GetDifficultyMealStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetDifficultyMealStatisticsUseCase(this._repository);

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
