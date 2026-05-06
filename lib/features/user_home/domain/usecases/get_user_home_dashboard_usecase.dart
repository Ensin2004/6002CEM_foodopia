import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_home_dashboard.dart';
import '../repositories/user_home_repository.dart';

class GetUserHomeDashboardUseCase {
  final UserHomeRepository repository;

  GetUserHomeDashboardUseCase(this.repository);

  Future<Either<Failure, UserHomeDashboard>> execute(String userName) {
    return repository.getDashboard(userName);
  }
}
