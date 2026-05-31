import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_statistics.dart';
import '../repositories/statistics_repository.dart';

class GetAdminGenderStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetAdminGenderStatisticsUseCase(this._repository);

  Future<Either<Failure, AdminGenderStatistics>> execute({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getAdminGender(startDate: startDate, endDate: endDate);
  }
}
