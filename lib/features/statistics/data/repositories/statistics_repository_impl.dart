import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/admin_statistics.dart';
import '../../domain/entities/calories_intake_statistics.dart';
import '../../domain/entities/calories_posted_statistics.dart';
import '../../domain/entities/difficulty_meal_statistics.dart';
import '../../domain/entities/food_analytic_statistics.dart';
import '../../domain/entities/meal_plan_method_statistics.dart';
import '../../domain/entities/meal_planned_time_statistics.dart';
import '../../domain/entities/most_cooked_recipe_statistics.dart';
import '../../domain/entities/post_analytic_statistics.dart';
import '../../domain/entities/post_difficulty_statistics.dart';
import '../../domain/entities/posted_meal_time_statistics.dart';
import '../../domain/entities/statistics_dashboard.dart';
import '../../domain/repositories/statistics_repository.dart';
import '../datasources/statistics_local_datasource.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  final StatisticsLocalDataSource localDataSource;

  const StatisticsRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, StatisticsDashboard>> getUserStatistics() async {
    try {
      return Right(await localDataSource.getUserStatistics());
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load statistics'));
    }
  }

  @override
  Future<Either<Failure, StatisticsDashboard>> getAdminStatistics() async {
    try {
      return Right(await localDataSource.getAdminStatistics());
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load statistics'));
    }
  }

  @override
  Future<Either<Failure, MealPlannedTimeStatistics>> getMealPlannedTime({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await localDataSource.getMealPlannedTime(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load meal planned time'));
    }
  }

  @override
  Future<Either<Failure, FoodAnalyticStatistics>> getFoodAnalytic({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await localDataSource.getFoodAnalytic(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load food analytic'));
    }
  }

  @override
  Future<Either<Failure, CaloriesIntakeStatistics>> getCaloriesIntake({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await localDataSource.getCaloriesIntake(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load calories intake'));
    }
  }

  @override
  Future<Either<Failure, DifficultyMealStatistics>> getDifficultyMeals({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await localDataSource.getDifficultyMeals(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load difficulty meals'));
    }
  }

  @override
  Future<Either<Failure, MealPlanMethodStatistics>> getMealPlanMethods({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await localDataSource.getMealPlanMethods(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load meal plan methods'));
    }
  }

  @override
  Future<Either<Failure, PostAnalyticStatistics>> getPostAnalytic({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await localDataSource.getPostAnalytic(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load post analytic'));
    }
  }

  @override
  Future<Either<Failure, CaloriesPostedStatistics>> getCaloriesPosted({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await localDataSource.getCaloriesPosted(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load calories posted'));
    }
  }

  @override
  Future<Either<Failure, PostedMealTimeStatistics>> getPostedMealTime({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await localDataSource.getPostedMealTime(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load posted meal time'));
    }
  }

  @override
  Future<Either<Failure, MostCookedRecipeStatistics>> getMostCookedRecipes({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await localDataSource.getMostCookedRecipes(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load most cooked recipes'));
    }
  }

  @override
  Future<Either<Failure, PostDifficultyStatistics>> getPostDifficulty({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await localDataSource.getPostDifficulty(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load difficulty posted'));
    }
  }

  @override
  Future<Either<Failure, AdminMealAnalyticStatistics>> getAdminMealAnalytic({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await localDataSource.getAdminMealAnalytic(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load meal analytic'));
    }
  }

  @override
  Future<Either<Failure, AdminPostAnalyticStatistics>> getAdminPostAnalytic({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await localDataSource.getAdminPostAnalytic(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load post analytic'));
    }
  }

  @override
  Future<Either<Failure, AdminDietaryPreferenceStatistics>>
  getAdminDietaryPreference({DateTime? startDate, DateTime? endDate}) async {
    try {
      return Right(
        await localDataSource.getAdminDietaryPreference(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load dietary preference'));
    }
  }
}
