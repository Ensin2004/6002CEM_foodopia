import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_home_dashboard.dart';

/// Repository interface for user home operations.
/// Defines data operations for the home dashboard and weather.
abstract class UserHomeRepository {
  /// Retrieves the user home dashboard.
  ///
  /// [userName] is the fallback user name to display.
  /// Returns either a failure or the user home dashboard on success.
  Future<Either<Failure, UserHomeDashboard>> getDashboard(String userName);

  /// Retrieves today's weather information.
  ///
  /// Returns either a failure or the weather data on success.
  Future<Either<Failure, UserHomeWeather>> getTodayWeather();
}