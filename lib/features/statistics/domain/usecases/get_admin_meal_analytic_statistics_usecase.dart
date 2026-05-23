import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_statistics.dart';
import '../repositories/statistics_repository.dart';

class GetAdminMealAnalyticStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetAdminMealAnalyticStatisticsUseCase(this._repository);

  Future<Either<Failure, AdminMealAnalyticStatistics>> execute({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getAdminMealAnalytic(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
