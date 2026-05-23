import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/most_cooked_recipe_statistics.dart';
import '../repositories/statistics_repository.dart';

class GetMostCookedRecipeStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetMostCookedRecipeStatisticsUseCase(this._repository);

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
