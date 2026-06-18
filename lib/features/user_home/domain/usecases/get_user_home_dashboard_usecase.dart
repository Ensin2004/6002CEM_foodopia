import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_home_dashboard.dart';
import '../repositories/user_home_repository.dart';

/// Use case for retrieving the user home dashboard.
/// Encapsulates the business logic for fetching home dashboard data.
class GetUserHomeDashboardUseCase {
  /// Repository instance for data operations.
  final UserHomeRepository repository;

  /// Creates a new get user home dashboard use case instance.
  GetUserHomeDashboardUseCase(this.repository);

  /// Executes the use case with the given user name.
  ///
  /// [userName] is the fallback user name to display.
  /// Returns either a failure or the user home dashboard on success.
  Future<Either<Failure, UserHomeDashboard>> execute(String userName) {
    // Delegate to repository to retrieve the dashboard.
    return repository.getDashboard(userName);
  }
}