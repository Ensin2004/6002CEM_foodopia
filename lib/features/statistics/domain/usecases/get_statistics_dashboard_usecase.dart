// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/statistics_dashboard.dart';
import '../repositories/statistics_repository.dart';

// Use case for loading the main statistics dashboard.
// It chooses the admin or normal user dashboard based on the current role.
// Handles GetStatisticsDashboardUseCase for this part of the statistics page.
class GetStatisticsDashboardUseCase {
  final StatisticsRepository _repository;

  const GetStatisticsDashboardUseCase(this._repository);

  // Handles execute for this part of the statistics page.
  Future<Either<Failure, StatisticsDashboard>> execute({
    required bool isAdmin,
  }) {
    // Admins get system-wide statistics, while normal users get their own
    // personal/community statistics.
    return isAdmin
        ? _repository.getAdminStatistics()
        : _repository.getUserStatistics();
  }
}
