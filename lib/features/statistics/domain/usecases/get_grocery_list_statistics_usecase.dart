// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/grocery_list_statistics.dart';
import '../repositories/statistics_repository.dart';

// Handles GetGroceryListStatisticsUseCase for this part of the statistics page.
class GetGroceryListStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetGroceryListStatisticsUseCase(this._repository);

  // Handles execute for this part of the statistics page.
  Future<Either<Failure, GroceryListStatistics>> execute({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getGroceryLists(startDate: startDate, endDate: endDate);
  }
}
