import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_home_dashboard.dart';
import '../repositories/admin_home_repository.dart';

/// Use case for retrieving the admin home dashboard.
/// Encapsulates the business logic for fetching admin dashboard data.
class GetAdminHomeDashboardUseCase {
  /// Repository instance for data operations.
  final AdminHomeRepository repository;

  /// Creates a new get admin home dashboard use case instance.
  GetAdminHomeDashboardUseCase(this.repository);

  /// Executes the use case with the given admin name.
  ///
  /// [adminName] is the fallback admin name to display.
  /// Returns either a failure or the admin home dashboard on success.
  Future<Either<Failure, AdminHomeDashboard>> execute(String adminName) {
    // Delegate to repository to retrieve the dashboard.
    return repository.getDashboard(adminName);
  }
}