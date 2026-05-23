import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/meal_plan_method_statistics.dart';
import '../repositories/statistics_repository.dart';

class GetMealPlanMethodStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetMealPlanMethodStatisticsUseCase(this._repository);

  Future<Either<Failure, MealPlanMethodStatistics>> execute({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getMealPlanMethods(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
