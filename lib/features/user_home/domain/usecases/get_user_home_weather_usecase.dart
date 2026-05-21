import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_home_dashboard.dart';
import '../repositories/user_home_repository.dart';

class GetUserHomeWeatherUseCase {
  final UserHomeRepository repository;

  GetUserHomeWeatherUseCase(this.repository);

  Future<Either<Failure, UserHomeWeather>> execute() {
    return repository.getTodayWeather();
  }
}
