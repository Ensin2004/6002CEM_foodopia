import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/food_analytic_statistics.dart';
import '../repositories/statistics_repository.dart';

class GetFoodAnalyticStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetFoodAnalyticStatisticsUseCase(this._repository);

  Future<Either<Failure, FoodAnalyticStatistics>> execute({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getFoodAnalytic(startDate: startDate, endDate: endDate);
  }
}
