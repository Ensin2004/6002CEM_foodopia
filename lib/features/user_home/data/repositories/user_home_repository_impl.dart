import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/user_home_dashboard.dart';
import '../../domain/repositories/user_home_repository.dart';
import '../datasources/user_home_remote_datasource.dart';
import '../datasources/user_home_weather_datasource.dart';

/// Implementation of the user home repository.
/// Coordinates data from remote and weather data sources.
class UserHomeRepositoryImpl implements UserHomeRepository {
  /// Remote data source for user home dashboard operations.
  final UserHomeRemoteDataSource remoteDataSource;

  /// Data source for weather information.
  final UserHomeWeatherDataSource weatherDataSource;

  /// Creates a new user home repository implementation instance.
  UserHomeRepositoryImpl({
    required this.remoteDataSource,
    required this.weatherDataSource,
  });

  /// Retrieves the user home dashboard.
  ///
  /// [userName] is the fallback user name to display.
  /// Returns either a failure or the user home dashboard on success.
  @override
  Future<Either<Failure, UserHomeDashboard>> getDashboard(
      String userName,
      ) async {
    try {
      // Delegate to remote data source.
      final dashboard = await remoteDataSource.getDashboard(userName);
      return Right(dashboard);
    } catch (e) {
      // Map any exception to a server failure.
      return Left(ServerFailure(message: e.toString()));
    }
  }

  /// Retrieves today's weather information.
  ///
  /// Returns either a failure or the weather data on success.
  @override
  Future<Either<Failure, UserHomeWeather>> getTodayWeather() async {
    try {
      // Delegate to weather data source.
      final weather = await weatherDataSource.getTodayWeather();
      return Right(weather);
    } catch (e) {
      // Map any exception to a network failure.
      return Left(NetworkFailure(message: e.toString()));
    }
  }
}