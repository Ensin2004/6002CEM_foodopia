import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/meal_plan_dashboard.dart';
import '../../domain/repositories/meal_plan_repository.dart';
import '../datasources/meal_plan_mock_datasource.dart';
import '../datasources/meal_plan_weather_datasource.dart';

class MealPlanRepositoryImpl implements MealPlanRepository {
  final MealPlanMockDataSource mockDataSource;
  final MealPlanWeatherDataSource weatherDataSource;

  const MealPlanRepositoryImpl({
    required this.mockDataSource,
    required this.weatherDataSource,
  });

  @override
  Future<Either<Failure, MealPlanDashboard>> getDashboard() async {
    try {
      final dashboard = await mockDataSource.getDashboard();
      return Right(dashboard);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MealPlanWeather>> getTodayWeather() async {
    try {
      final weather = await weatherDataSource.getTodayWeather();
      return Right(weather);
    } catch (e) {
      return Left(NetworkFailure(message: e.toString()));
    }
  }
}
