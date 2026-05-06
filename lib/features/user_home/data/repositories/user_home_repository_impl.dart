import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/user_home_dashboard.dart';
import '../../domain/repositories/user_home_repository.dart';
import '../datasources/user_home_mock_datasource.dart';
import '../datasources/user_home_weather_datasource.dart';

class UserHomeRepositoryImpl implements UserHomeRepository {
  final UserHomeMockDataSource mockDataSource;
  final UserHomeWeatherDataSource weatherDataSource;

  UserHomeRepositoryImpl({
    required this.mockDataSource,
    required this.weatherDataSource,
  });

  @override
  Future<Either<Failure, UserHomeDashboard>> getDashboard(
    String userName,
  ) async {
    try {
      final dashboard = await mockDataSource.getDashboard(userName);
      return Right(dashboard);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserHomeWeather>> getTodayWeather() async {
    try {
      final weather = await weatherDataSource.getTodayWeather();
      return Right(weather);
    } catch (e) {
      return Left(NetworkFailure(message: e.toString()));
    }
  }
}
