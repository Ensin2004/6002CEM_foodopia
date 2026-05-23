import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/calories_intake_statistics.dart';
import '../repositories/statistics_repository.dart';

class GetCaloriesIntakeStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetCaloriesIntakeStatisticsUseCase(this._repository);

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
