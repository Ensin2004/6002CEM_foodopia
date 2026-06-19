import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_home_dashboard.dart';
import '../repositories/user_home_repository.dart';

/// Use case for retrieving today's weather information.
/// Encapsulates the business logic for fetching weather data.
class GetUserHomeWeatherUseCase {
  /// Repository instance for data operations.
  final UserHomeRepository repository;

  /// Creates a new get user home weather use case instance.
  GetUserHomeWeatherUseCase(this.repository);

  /// Executes the use case.
  ///
  /// Returns either a failure or the weather data on success.
  Future<Either<Failure, UserHomeWeather>> execute() {
    // Delegate to repository to retrieve the weather.
    return repository.getTodayWeather();
  }
}