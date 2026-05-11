import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/add_grocery_list_plan.dart';
import '../../domain/entities/add_meal_ai_plan.dart';
import '../../domain/entities/manage_grocery_list_detail.dart';
import '../../domain/entities/meal_plan_dashboard.dart';
import '../../domain/repositories/meal_plan_repository.dart';
import '../datasources/meal_plan_mock_datasource.dart';
import '../datasources/meal_plan_preferences_datasource.dart';
import '../datasources/meal_plan_weather_datasource.dart';

class MealPlanRepositoryImpl implements MealPlanRepository {
  final MealPlanMockDataSource mockDataSource;
  final MealPlanWeatherDataSource weatherDataSource;
  final MealPlanPreferencesDataSource preferencesDataSource;

  const MealPlanRepositoryImpl({
    required this.mockDataSource,
    required this.weatherDataSource,
    required this.preferencesDataSource,
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

  @override
  Future<Either<Failure, MealPlanPreferenceSummary>> getPreferences(
    String uid,
  ) async {
    try {
      final preferences = await preferencesDataSource.getPreferences(uid);
      return Right(preferences);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AddGroceryListPlan>> getAddGroceryListPlan() async {
    try {
      final plan = await mockDataSource.getAddGroceryListPlan();
      return Right(plan);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AddMealAiPlan>> getAddMealAiPlan({
    required String userId,
    required String mealType,
  }) async {
    try {
      final preferences = await preferencesDataSource.getPreferences(userId);
      final plan = await mockDataSource.getAddMealAiPlan(
        mealType: mealType,
        preferences: AddMealPreferenceSnapshot(
          diet: preferences.diet,
          allergies: preferences.allergies,
          dislikes: preferences.dislikes,
        ),
      );
      return Right(plan);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ManageGroceryListDetail>> getManageGroceryListDetail(
    String listId,
  ) async {
    try {
      final detail = await mockDataSource.getManageGroceryListDetail(listId);
      return Right(detail);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
