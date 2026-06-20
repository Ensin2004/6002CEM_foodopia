// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/most_cooked_recipe_statistics.dart';
import '../repositories/statistics_repository.dart';

// Handles GetMostCookedRecipeStatisticsUseCase for this part of the statistics page.
class GetMostCookedRecipeStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetMostCookedRecipeStatisticsUseCase(this._repository);

  // Handles execute for this part of the statistics page.
  Future<Either<Failure, MostCookedRecipeStatistics>> execute({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getMostCookedRecipes(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
