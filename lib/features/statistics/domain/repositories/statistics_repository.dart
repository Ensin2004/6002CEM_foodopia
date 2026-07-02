// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_statistics.dart';
import '../entities/calories_intake_statistics.dart';
import '../entities/calories_posted_statistics.dart';
import '../entities/cooking_time_statistics.dart';
import '../entities/difficulty_meal_statistics.dart';
import '../entities/food_analytic_statistics.dart';
import '../entities/grocery_list_statistics.dart';
import '../entities/meal_plan_method_statistics.dart';
import '../entities/meal_planned_time_statistics.dart';
import '../entities/most_cooked_recipe_statistics.dart';
import '../entities/post_analytic_statistics.dart';
import '../entities/post_difficulty_statistics.dart';
import '../entities/posted_meal_time_statistics.dart';
import '../entities/recipe_performance_statistics.dart';
import '../entities/statistics_dashboard.dart';

// This contract lists every statistics report that the app can ask for.
// The domain and presentation layers use this, so they do not need to know
// which Firestore collections or local sources are used underneath.
// Handles StatisticsRepository for this part of the statistics page.
abstract class StatisticsRepository {
  Future<Either<Failure, StatisticsDashboard>> getUserStatistics();

  Future<Either<Failure, StatisticsDashboard>> getAdminStatistics();

  // Handles getMealPlannedTime for this part of the statistics page.
  Future<Either<Failure, MealPlannedTimeStatistics>> getMealPlannedTime({
    DateTime? startDate,
    DateTime? endDate,
  });

  // Handles getCookingTime for this part of the statistics page.
  Future<Either<Failure, CookingTimeStatistics>> getCookingTime({
    DateTime? startDate,
    DateTime? endDate,
  });

  // Handles getGroceryLists for this part of the statistics page.
  Future<Either<Failure, GroceryListStatistics>> getGroceryLists({
    DateTime? startDate,
    DateTime? endDate,
  });

  // Handles getFoodAnalytic for this part of the statistics page.
  Future<Either<Failure, FoodAnalyticStatistics>> getFoodAnalytic({
    DateTime? startDate,
    DateTime? endDate,
  });

  // Handles getCaloriesIntake for this part of the statistics page.
  Future<Either<Failure, CaloriesIntakeStatistics>> getCaloriesIntake({
    DateTime? startDate,
    DateTime? endDate,
  });

  // Handles getDifficultyMeals for this part of the statistics page.
  Future<Either<Failure, DifficultyMealStatistics>> getDifficultyMeals({
    DateTime? startDate,
    DateTime? endDate,
  });

  // Handles getMealPlanMethods for this part of the statistics page.
  Future<Either<Failure, MealPlanMethodStatistics>> getMealPlanMethods({
    DateTime? startDate,
    DateTime? endDate,
  });

  // Handles getPostAnalytic for this part of the statistics page.
  Future<Either<Failure, PostAnalyticStatistics>> getPostAnalytic({
    DateTime? startDate,
    DateTime? endDate,
  });

  // Handles getCaloriesPosted for this part of the statistics page.
  Future<Either<Failure, CaloriesPostedStatistics>> getCaloriesPosted({
    DateTime? startDate,
    DateTime? endDate,
  });

  // Handles getPostedMealTime for this part of the statistics page.
  Future<Either<Failure, PostedMealTimeStatistics>> getPostedMealTime({
    DateTime? startDate,
    DateTime? endDate,
  });

  // Handles getRecipePerformance for this part of the statistics page.
  Future<Either<Failure, RecipePerformanceStatistics>> getRecipePerformance();

  Future<Either<Failure, MostCookedRecipeStatistics>> getMostCookedRecipes({
    DateTime? startDate,
    DateTime? endDate,
  });

  // Handles getPostDifficulty for this part of the statistics page.
  Future<Either<Failure, PostDifficultyStatistics>> getPostDifficulty({
    DateTime? startDate,
    DateTime? endDate,
  });

  // Handles getAdminMealAnalytic for this part of the statistics page.
  Future<Either<Failure, AdminMealAnalyticStatistics>> getAdminMealAnalytic({
    DateTime? startDate,
    DateTime? endDate,
  });

  // Handles getAdminPostAnalytic for this part of the statistics page.
  Future<Either<Failure, AdminPostAnalyticStatistics>> getAdminPostAnalytic({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, AdminDietaryPreferenceStatistics>>
  getAdminDietaryPreference({DateTime? startDate, DateTime? endDate});

  // Handles getAdminGender for this part of the statistics page.
  Future<Either<Failure, AdminGenderStatistics>> getAdminGender({
    DateTime? startDate,
    DateTime? endDate,
  });

  // Handles getAdminUserUsage for this part of the statistics page.
  Future<Either<Failure, AdminUserUsageStatistics>> getAdminUserUsage({
    DateTime? startDate,
    DateTime? endDate,
  });

  // Handles getAdminUsageForecast for this part of the statistics page.
  Future<Either<Failure, AdminUserUsageStatistics>> getAdminUsageForecast({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, AdminModerationStatistics>> getAdminModeration({
    DateTime? startDate,
    DateTime? endDate,
  });

  // Handles getAdminHubRating for this part of the statistics page.
  Future<Either<Failure, AdminHubRatingStatistics>> getAdminHubRating({
    DateTime? startDate,
    DateTime? endDate,
  });
}
