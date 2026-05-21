import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/statistics_dashboard.dart';

abstract class StatisticsRepository {
  Future<Either<Failure, StatisticsDashboard>> getUserStatistics();

  Future<Either<Failure, StatisticsDashboard>> getAdminStatistics();
}
