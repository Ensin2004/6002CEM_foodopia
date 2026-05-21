import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/statistics_dashboard.dart';
import '../../domain/repositories/statistics_repository.dart';
import '../datasources/statistics_mock_datasource.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  final StatisticsMockDataSource mockDataSource;

  const StatisticsRepositoryImpl({required this.mockDataSource});

  @override
  Future<Either<Failure, StatisticsDashboard>> getUserStatistics() async {
    try {
      return Right(await mockDataSource.getUserStatistics());
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load statistics'));
    }
  }

  @override
  Future<Either<Failure, StatisticsDashboard>> getAdminStatistics() async {
    try {
      return Right(await mockDataSource.getAdminStatistics());
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load statistics'));
    }
  }
}
