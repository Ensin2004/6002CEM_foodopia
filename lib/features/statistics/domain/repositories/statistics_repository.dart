import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/admin_statistics.dart';
import '../entities/calories_intake_statistics.dart';
import '../entities/calories_posted_statistics.dart';
import '../entities/difficulty_meal_statistics.dart';
import '../entities/food_analytic_statistics.dart';
import '../entities/meal_plan_method_statistics.dart';
import '../entities/meal_planned_time_statistics.dart';
import '../entities/most_cooked_recipe_statistics.dart';
import '../entities/post_analytic_statistics.dart';
import '../entities/post_difficulty_statistics.dart';
import '../entities/posted_meal_time_statistics.dart';
import '../entities/recipe_performance_statistics.dart';
import '../entities/statistics_dashboard.dart';

abstract class StatisticsRepository {
  Future<Either<Failure, StatisticsDashboard>> getUserStatistics();

  Future<Either<Failure, StatisticsDashboard>> getAdminStatistics();

  Future<Either<Failure, MealPlannedTimeStatistics>> getMealPlannedTime({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, FoodAnalyticStatistics>> getFoodAnalytic({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, CaloriesIntakeStatistics>> getCaloriesIntake({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, DifficultyMealStatistics>> getDifficultyMeals({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, MealPlanMethodStatistics>> getMealPlanMethods({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, PostAnalyticStatistics>> getPostAnalytic({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, CaloriesPostedStatistics>> getCaloriesPosted({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, PostedMealTimeStatistics>> getPostedMealTime({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, RecipePerformanceStatistics>> getRecipePerformance();

  Future<Either<Failure, MostCookedRecipeStatistics>> getMostCookedRecipes({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, PostDifficultyStatistics>> getPostDifficulty({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, AdminMealAnalyticStatistics>> getAdminMealAnalytic({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, AdminPostAnalyticStatistics>> getAdminPostAnalytic({
    DateTime? startDate,
    DateTime? endDate,
  });

  Future<Either<Failure, AdminDietaryPreferenceStatistics>>
  getAdminDietaryPreference({DateTime? startDate, DateTime? endDate});
}
