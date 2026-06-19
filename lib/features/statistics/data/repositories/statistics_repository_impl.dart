// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/admin_statistics.dart';
import '../../domain/entities/calories_intake_statistics.dart';
import '../../domain/entities/calories_posted_statistics.dart';
import '../../domain/entities/cooking_time_statistics.dart';
import '../../domain/entities/difficulty_meal_statistics.dart';
import '../../domain/entities/food_analytic_statistics.dart';
import '../../domain/entities/grocery_list_statistics.dart';
import '../../domain/entities/meal_plan_method_statistics.dart';
import '../../domain/entities/meal_planned_time_statistics.dart';
import '../../domain/entities/most_cooked_recipe_statistics.dart';
import '../../domain/entities/post_analytic_statistics.dart';
import '../../domain/entities/post_difficulty_statistics.dart';
import '../../domain/entities/posted_meal_time_statistics.dart';
import '../../domain/entities/recipe_performance_statistics.dart';
import '../../domain/entities/statistics_dashboard.dart';
import '../../domain/repositories/statistics_repository.dart';
import '../datasources/statistics_local_datasource.dart';
import '../datasources/statistics_remote_datasource.dart';
import '../models/statistics_dashboard_model.dart';

// Repository layer for statistics.
// It decides whether each report comes from local fixed data or Firestore data,
// and converts any error into a Failure that the UI can understand.
// Handles StatisticsRepositoryImpl for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class StatisticsRepositoryImpl implements StatisticsRepository {
  final StatisticsLocalDataSource localDataSource;
  final StatisticsRemoteDataSource remoteDataSource;

  // Handles StatisticsRepositoryImpl for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const StatisticsRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  // Handles getUserStatistics for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  Future<Either<Failure, StatisticsDashboard>> getUserStatistics() async {
    try {
      // The dashboard menu is local, while the hero cards use live database
      // numbers from the current user's meal plans and shared recipes.
      final localDashboard = await localDataSource.getUserStatistics();
      final userHeroSlides = await remoteDataSource.getUserSelfHeroSlides();
      final communityHeroSlides = await remoteDataSource
          .getUserCommunityHeroSlides();

      return Right(
        StatisticsDashboardModel(
          heroSlides: userHeroSlides,
          communityHeroSlides: communityHeroSlides,
          menuItems: localDashboard.menuItems,
          communityMenuItems: localDashboard.communityMenuItems,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load statistics'));
    }
  }

  // Handles getAdminStatistics for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  Future<Either<Failure, StatisticsDashboard>> getAdminStatistics() async {
    try {
      // Admin dashboard keeps the menu locally but fills the top cards with
      // system-wide Firestore statistics.
      final localDashboard = await localDataSource.getAdminStatistics();
      final adminHeroSlides = await remoteDataSource.getAdminHeroSlides();

      return Right(
        StatisticsDashboardModel(
          heroSlides: adminHeroSlides,
          communityHeroSlides: localDashboard.communityHeroSlides,
          menuItems: localDashboard.menuItems,
          communityMenuItems: localDashboard.communityMenuItems,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load statistics'));
    }
  }

  // Handles getMealPlannedTime for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  Future<Either<Failure, MealPlannedTimeStatistics>> getMealPlannedTime({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await remoteDataSource.getUserMealPlannedTime(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load meal planned time'));
    }
  }

  // Handles getCookingTime for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  Future<Either<Failure, CookingTimeStatistics>> getCookingTime({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await remoteDataSource.getUserCookingTime(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load cooking time'));
    }
  }

  // Handles getGroceryLists for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  Future<Either<Failure, GroceryListStatistics>> getGroceryLists({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await remoteDataSource.getUserGroceryLists(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load grocery list'));
    }
  }

  // Handles getFoodAnalytic for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  Future<Either<Failure, FoodAnalyticStatistics>> getFoodAnalytic({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await remoteDataSource.getUserFoodAnalytic(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load food analytic'));
    }
  }

  // Handles getCaloriesIntake for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  Future<Either<Failure, CaloriesIntakeStatistics>> getCaloriesIntake({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await remoteDataSource.getUserCaloriesIntake(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load calories intake'));
    }
  }

  // Handles getDifficultyMeals for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  Future<Either<Failure, DifficultyMealStatistics>> getDifficultyMeals({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await remoteDataSource.getUserDifficultyMeals(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load difficulty meals'));
    }
  }

  // Handles getMealPlanMethods for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  Future<Either<Failure, MealPlanMethodStatistics>> getMealPlanMethods({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await remoteDataSource.getUserMealPlanMethods(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load meal plan methods'));
    }
  }

  // Handles getPostAnalytic for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  Future<Either<Failure, PostAnalyticStatistics>> getPostAnalytic({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await remoteDataSource.getUserPostAnalytic(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load post analytic'));
    }
  }

  // Handles getCaloriesPosted for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  Future<Either<Failure, CaloriesPostedStatistics>> getCaloriesPosted({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await remoteDataSource.getUserCaloriesPosted(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load calories posted'));
    }
  }

  // Handles getPostedMealTime for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  Future<Either<Failure, PostedMealTimeStatistics>> getPostedMealTime({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // This report still uses local sample data, unlike most statistics that
      // read live Firestore records through the remote data source.
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
  Future<Either<Failure, RecipePerformanceStatistics>>
  getRecipePerformance() async {
    try {
      return Right(await remoteDataSource.getUserRecipePerformance());
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load recipe performance'));
    }
  }

  // Handles getMostCookedRecipes for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  Future<Either<Failure, MostCookedRecipeStatistics>> getMostCookedRecipes({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await remoteDataSource.getUserMostCookedRecipes(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load most cooked recipes'));
    }
  }

  // Handles getPostDifficulty for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  Future<Either<Failure, PostDifficultyStatistics>> getPostDifficulty({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await remoteDataSource.getUserPostDifficulty(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load difficulty posted'));
    }
  }

  // Handles getAdminMealAnalytic for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  Future<Either<Failure, AdminMealAnalyticStatistics>> getAdminMealAnalytic({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await remoteDataSource.getAdminMealAnalytic(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load meal analytic'));
    }
  }

  // Handles getAdminPostAnalytic for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  Future<Either<Failure, AdminPostAnalyticStatistics>> getAdminPostAnalytic({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await remoteDataSource.getAdminPostAnalytic(
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
        await remoteDataSource.getAdminDietaryPreference(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load dietary preference'));
    }
  }

  // Handles getAdminGender for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  Future<Either<Failure, AdminGenderStatistics>> getAdminGender({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await remoteDataSource.getAdminGender(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load gender statistic'));
    }
  }

  // Handles getAdminUserUsage for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  Future<Either<Failure, AdminUserUsageStatistics>> getAdminUserUsage({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await remoteDataSource.getAdminUserUsage(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load user usage'));
    }
  }

  // Handles getAdminUsageForecast for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  Future<Either<Failure, AdminUserUsageStatistics>> getAdminUsageForecast({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await remoteDataSource.getAdminUsageForecast(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load usage forecast'));
    }
  }

  // Handles getAdminNutrientInsight for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  Future<Either<Failure, CaloriesIntakeStatistics>> getAdminNutrientInsight({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await remoteDataSource.getAdminNutrientInsight(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load nutrient insight'));
    }
  }

  // Handles getAdminHubRating for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  Future<Either<Failure, AdminHubRatingStatistics>> getAdminHubRating({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      return Right(
        await remoteDataSource.getAdminHubRating(
          startDate: startDate,
          endDate: endDate,
        ),
      );
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load hub rating'));
    }
  }
}
