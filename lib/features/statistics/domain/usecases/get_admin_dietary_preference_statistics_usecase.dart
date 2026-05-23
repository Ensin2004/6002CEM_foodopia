import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_statistics.dart';
import '../repositories/statistics_repository.dart';

class GetAdminDietaryPreferenceStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetAdminDietaryPreferenceStatisticsUseCase(this._repository);

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
