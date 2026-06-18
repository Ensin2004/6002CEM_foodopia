import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/admin_home_dashboard.dart';
import '../../domain/repositories/admin_home_repository.dart';
import '../datasources/admin_home_remote_datasource.dart';

/// Implementation of the admin home repository.
/// Coordinates data from the remote data source.
class AdminHomeRepositoryImpl implements AdminHomeRepository {
  /// Remote data source for admin home operations.
  final AdminHomeRemoteDataSource remoteDataSource;

  /// Creates a new admin home repository implementation instance.
  AdminHomeRepositoryImpl({required this.remoteDataSource});

  /// Retrieves the admin home dashboard.
  ///
  /// [adminName] is the fallback admin name to display.
  /// Returns either a failure or the admin home dashboard on success.
  @override
  Future<Either<Failure, AdminHomeDashboard>> getDashboard(
      String adminName,
      ) async {
    try {
      // Delegate to remote data source.
      final dashboard = await remoteDataSource.getDashboard(adminName);
      return Right(dashboard);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }
}