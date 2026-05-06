import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_home_dashboard.dart';

abstract class AdminHomeRepository {
  Future<Either<Failure, AdminHomeDashboard>> getDashboard(String adminName);
}
