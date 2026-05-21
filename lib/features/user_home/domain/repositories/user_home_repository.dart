import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_home_dashboard.dart';

abstract class UserHomeRepository {
  Future<Either<Failure, UserHomeDashboard>> getDashboard(String userName);

  Future<Either<Failure, UserHomeWeather>> getTodayWeather();
}
