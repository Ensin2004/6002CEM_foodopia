// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_statistics.dart';
import '../repositories/statistics_repository.dart';

// Handles GetAdminGenderStatisticsUseCase for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class GetAdminGenderStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetAdminGenderStatisticsUseCase(this._repository);

  // Handles execute for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Future<Either<Failure, AdminGenderStatistics>> execute({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getAdminGender(startDate: startDate, endDate: endDate);
  }
}
