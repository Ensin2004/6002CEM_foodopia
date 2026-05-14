import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/statistics_dashboard.dart';
import '../repositories/statistics_repository.dart';

class GetStatisticsDashboardUseCase {
  final StatisticsRepository _repository;

  const GetStatisticsDashboardUseCase(this._repository);

  Future<Either<Failure, StatisticsDashboard>> execute({
    required bool isAdmin,
  }) {
    return isAdmin
        ? _repository.getAdminStatistics()
        : _repository.getUserStatistics();
  }
}
