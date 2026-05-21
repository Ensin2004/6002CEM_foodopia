import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/admin_home_dashboard.dart';
import '../../domain/repositories/admin_home_repository.dart';
import '../datasources/admin_home_mock_datasource.dart';

class AdminHomeRepositoryImpl implements AdminHomeRepository {
  final AdminHomeMockDataSource mockDataSource;

  AdminHomeRepositoryImpl({required this.mockDataSource});

  @override
  Future<Either<Failure, AdminHomeDashboard>> getDashboard(
    String adminName,
  ) async {
    try {
      final dashboard = await mockDataSource.getDashboard(adminName);
      return Right(dashboard);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
