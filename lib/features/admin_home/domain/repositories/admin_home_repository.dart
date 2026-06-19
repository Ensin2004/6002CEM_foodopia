import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_home_dashboard.dart';

/// Repository interface for admin home operations.
/// Defines data operations for the admin home dashboard.
abstract class AdminHomeRepository {
  /// Retrieves the admin home dashboard.
  ///
  /// [adminName] is the fallback admin name to display.
  /// Returns either a failure or the admin home dashboard on success.
  Future<Either<Failure, AdminHomeDashboard>> getDashboard(String adminName);
}