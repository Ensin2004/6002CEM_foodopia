import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/grocery_list_statistics.dart';
import '../repositories/statistics_repository.dart';

class GetGroceryListStatisticsUseCase {
  final StatisticsRepository _repository;

  const GetGroceryListStatisticsUseCase(this._repository);

  Future<Either<Failure, GroceryListStatistics>> execute({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _repository.getGroceryLists(startDate: startDate, endDate: endDate);
  }
}
