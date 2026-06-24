import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_statistics.dart';
import '../repositories/statistics_repository.dart';

// Handles GetAdminDietaryPreferenceStatisticsUseCase for this part of the statistics page.
class GetAdminDietaryPreferenceStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetAdminDietaryPreferenceStatisticsUseCase(this._repository);

  // Handles execute for this part of the statistics page.
  Future<Either<Failure, AdminDietaryPreferenceStatistics>> execute({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getAdminDietaryPreference(
      startDate: startDate,
      endDate: endDate,
    );
  }
}
