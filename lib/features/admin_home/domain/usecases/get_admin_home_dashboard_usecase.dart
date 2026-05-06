import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_home_dashboard.dart';
import '../repositories/admin_home_repository.dart';

class GetAdminHomeDashboardUseCase {
  final AdminHomeRepository repository;

  GetAdminHomeDashboardUseCase(this.repository);

  Future<Either<Failure, AdminHomeDashboard>> execute(String adminName) {
    return repository.getDashboard(adminName);
  }
}
