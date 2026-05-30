import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/statistics_dashboard_model.dart';
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

class StatisticsLocalDataSource {
  Future<StatisticsDashboardModel> getUserStatistics() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    return const StatisticsDashboardModel(
      heroSlides: [
        StatisticsHeroSlide(
          title: 'Overall Meals',
          type: StatisticsHeroSlideType.overview,
          metrics: [
            StatisticsMetric(
              label: 'Planned Meal',
              value: '50',
              tone: StatisticsMetricTone.positive,
            ),
            StatisticsMetric(
              label: 'Unplanned Meal',
              value: '2',
              tone: StatisticsMetricTone.negative,
            ),
            StatisticsMetric(
              label: 'Planned Meals',
              value: '12',
              suffix: 'Days',
              tone: StatisticsMetricTone.neutral,
            ),
            StatisticsMetric(
              label: 'Unplanned Meals',
              value: '2',
              suffix: 'Days',
              tone: StatisticsMetricTone.neutral,
            ),
          ],
        ),
        StatisticsHeroSlide(
          title: 'Days Using This App',
          type: StatisticsHeroSlideType.appUsage,
          metrics: [
            StatisticsMetric(label: 'Days', value: '40'),
            StatisticsMetric(
              label: 'Day with Planned Meals',
              value: '35',
              tone: StatisticsMetricTone.positive,
            ),
            StatisticsMetric(
              label: 'Unplanned Meals',
              value: '5',
              tone: StatisticsMetricTone.negative,
            ),
          ],
          progress: StatisticsProgress(
            positivePercent: 0.8,
            negativePercent: 0.2,
          ),
        ),
        StatisticsHeroSlide(
          title: 'Achievement',
          type: StatisticsHeroSlideType.achievement,
          metrics: [
            StatisticsMetric(label: 'Total Dish', value: '50'),
            StatisticsMetric(label: 'Different Category', value: '5'),
            StatisticsMetric(label: 'Difficulty Dishes', value: '4.1'),
            StatisticsMetric(
              label: 'Cooking Time',
              value: '9',
              suffix: 'Hrs 30 Min',
              isWide: true,
            ),
          ],
        ),
      ],
      menuItems: [
        StatisticsMenuItem(title: 'Food Analytic'),
        StatisticsMenuItem(title: 'Time Taken For Cooking'),
        StatisticsMenuItem(title: 'Calories Intake'),
        StatisticsMenuItem(title: 'Meal Planned Time'),
        StatisticsMenuItem(title: 'Method For Creating Plan'),
        StatisticsMenuItem(title: 'Difficulty'),
      ],
      communityMenuItems: [
        StatisticsMenuItem(title: 'Post Analytic'),
        StatisticsMenuItem(title: 'Most Calories Posted Meal'),
        StatisticsMenuItem(title: 'Recipe Performance'),
        StatisticsMenuItem(title: 'Most Cooked Recipe By Others'),
        StatisticsMenuItem(title: 'Difficulty Posted'),
      ],
    );
  }

  Future<StatisticsDashboardModel> getAdminStatistics() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    return const StatisticsDashboardModel(
      heroSlides: [
        StatisticsHeroSlide(
          title: 'Meal Planned Today',
          type: StatisticsHeroSlideType.overview,
          metrics: [
            StatisticsMetric(
              label: 'Meal Planned Today',
              value: '128',
              tone: StatisticsMetricTone.positive,
            ),
            StatisticsMetric(
              label: 'Average Difficulty Today',
              value: '3.8',
              tone: StatisticsMetricTone.neutral,
            ),
            StatisticsMetric(
              label: 'Top Meal Planned Today',
              value: 'Pesto Pasta',
              tone: StatisticsMetricTone.positive,
            ),
            StatisticsMetric(
              label: 'Top Planned Category Today',
              value: 'Asian',
              tone: StatisticsMetricTone.positive,
            ),
          ],
        ),
        StatisticsHeroSlide(
          title: 'Posted Today',
          type: StatisticsHeroSlideType.overview,
          metrics: [
            StatisticsMetric(
              label: 'Posted Today',
              value: '36',
              tone: StatisticsMetricTone.positive,
            ),
            StatisticsMetric(
              label: 'Average Difficulty Posted',
              value: '3.4',
              tone: StatisticsMetricTone.neutral,
            ),
            StatisticsMetric(
              label: 'Category Posted Today',
              value: '9',
              tone: StatisticsMetricTone.positive,
            ),
            StatisticsMetric(
              label: 'Top Rating Food Today',
              value: 'Grilled Fish',
              tone: StatisticsMetricTone.positive,
            ),
          ],
        ),
        StatisticsHeroSlide(
          title: 'Achievement',
          type: StatisticsHeroSlideType.achievement,
          metrics: [
            StatisticsMetric(
              label: 'Meal Planned In System',
              value: '2.4K',
              tone: StatisticsMetricTone.positive,
            ),
            StatisticsMetric(
              label: 'Recipe In System',
              value: '480',
              tone: StatisticsMetricTone.positive,
            ),
            StatisticsMetric(
              label: 'Category In System',
              value: '32',
              tone: StatisticsMetricTone.positive,
            ),
            StatisticsMetric(
              label: 'Post In System',
              value: '1.1K',
              tone: StatisticsMetricTone.positive,
            ),
          ],
        ),
      ],
      menuItems: [
        StatisticsMenuItem(title: 'Planned Meal Analytic'),
        StatisticsMenuItem(title: 'Post Analytic'),
        StatisticsMenuItem(title: 'Dietary Preference'),
      ],
      communityMenuItems: [
        StatisticsMenuItem(title: 'Gender'),
        StatisticsMenuItem(title: 'User Usage'),
        StatisticsMenuItem(title: 'Hub Rating'),
      ],
    );
  }

  Future<MealPlannedTimeStatistics> getMealPlannedTime({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final range = _resolveRange(startDate, endDate);

    return MealPlannedTimeStatistics(
      dateRange: _formatRange(range.start, range.end),
      totalDays: 10,
      totalMeals: 15,
      segments: [
        MealPlannedTimeSegment(
          title: 'Breakfast Meal',
          totalTaken: 8,
          color: Color(0xFF10A957),
          icon: Icons.breakfast_dining,
          meals: [
            MealPlannedItem(
              name: 'Pesto Pasta',
              amount: 5,
              plannedDate: DateTime(2024, 5, 12),
              icon: Icons.ramen_dining,
            ),
            MealPlannedItem(
              name: 'Breakfast Toast',
              amount: 2,
              plannedDate: DateTime(2024, 5, 14),
              icon: Icons.breakfast_dining,
            ),
            MealPlannedItem(
              name: 'Fruit Bowl',
              amount: 1,
              plannedDate: DateTime(2024, 5, 17),
              icon: Icons.local_dining,
            ),
          ],
        ),
        MealPlannedTimeSegment(
          title: 'Lunch Meal',
          totalTaken: 5,
          color: Color(0xFFFFB300),
          icon: Icons.wb_sunny_outlined,
          meals: [
            MealPlannedItem(
              name: 'Chicken Rice',
              amount: 2,
              plannedDate: DateTime(2024, 5, 13),
              icon: Icons.rice_bowl,
            ),
            MealPlannedItem(
              name: 'Vegetable Wrap',
              amount: 2,
              plannedDate: DateTime(2024, 5, 15),
              icon: Icons.lunch_dining,
            ),
            MealPlannedItem(
              name: 'Garden Salad',
              amount: 1,
              plannedDate: DateTime(2024, 5, 18),
              icon: Icons.eco,
            ),
          ],
        ),
        MealPlannedTimeSegment(
          title: 'Dinner Meal',
          totalTaken: 2,
          color: Color(0xFFFF4D5A),
          icon: Icons.nightlight_round,
          meals: [
            MealPlannedItem(
              name: 'Grilled Fish',
              amount: 1,
              plannedDate: DateTime(2024, 5, 16),
              icon: Icons.dinner_dining,
            ),
            MealPlannedItem(
              name: 'Soup Bowl',
              amount: 1,
              plannedDate: DateTime(2024, 5, 18),
              icon: Icons.soup_kitchen,
            ),
          ],
        ),
      ],
    );
  }

  Future<FoodAnalyticStatistics> getFoodAnalytic({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final range = _resolveRange(startDate, endDate);

    const dishItems = [
      FoodAnalyticBarItem(
        label: 'Pesto Pasta',
        value: 20,
        percent: 0.40,
        icon: Icons.ramen_dining,
        color: Color(0xFF21AEEA),
      ),
      FoodAnalyticBarItem(
        label: 'Chicken Bowl',
        value: 15,
        percent: 0.30,
        icon: Icons.rice_bowl,
        color: Color(0xFF21AEEA),
      ),
      FoodAnalyticBarItem(
        label: 'Garden Wrap',
        value: 12,
        percent: 0.20,
        icon: Icons.lunch_dining,
        color: Color(0xFF21AEEA),
      ),
      FoodAnalyticBarItem(
        label: 'Soup Set',
        value: 11,
        percent: 0.15,
        icon: Icons.soup_kitchen,
        color: Color(0xFF21AEEA),
      ),
      FoodAnalyticBarItem(
        label: 'Grilled Fish',
        value: 8,
        percent: 0.12,
        icon: Icons.dinner_dining,
        color: Color(0xFF21AEEA),
      ),
    ];

    const ingredientItems = [
      FoodAnalyticBarItem(
        label: 'Tomato',
        value: 34,
        percent: 0.34,
        icon: Icons.local_dining,
        color: Color(0xFF21AEEA),
      ),
      FoodAnalyticBarItem(
        label: 'Chicken',
        value: 28,
        percent: 0.28,
        icon: Icons.set_meal,
        color: Color(0xFF21AEEA),
      ),
      FoodAnalyticBarItem(
        label: 'Pasta',
        value: 25,
        percent: 0.25,
        icon: Icons.ramen_dining,
        color: Color(0xFF21AEEA),
      ),
      FoodAnalyticBarItem(
        label: 'Spinach',
        value: 18,
        percent: 0.18,
        icon: Icons.eco,
        color: Color(0xFF21AEEA),
      ),
      FoodAnalyticBarItem(
        label: 'Egg',
        value: 14,
        percent: 0.14,
        icon: Icons.egg_alt,
        color: Color(0xFF21AEEA),
      ),
    ];

    const categoryItems = [
      FoodAnalyticBarItem(
        label: 'Asian',
        value: 18,
        percent: 0.36,
        icon: Icons.rice_bowl,
        color: Color(0xFF21AEEA),
      ),
      FoodAnalyticBarItem(
        label: 'Italian',
        value: 16,
        percent: 0.32,
        icon: Icons.local_pizza,
        color: Color(0xFF21AEEA),
      ),
      FoodAnalyticBarItem(
        label: 'Healthy',
        value: 12,
        percent: 0.24,
        icon: Icons.eco,
        color: Color(0xFF21AEEA),
      ),
      FoodAnalyticBarItem(
        label: 'Western',
        value: 9,
        percent: 0.18,
        icon: Icons.lunch_dining,
        color: Color(0xFF21AEEA),
      ),
      FoodAnalyticBarItem(
        label: 'Soup',
        value: 6,
        percent: 0.12,
        icon: Icons.soup_kitchen,
        color: Color(0xFF21AEEA),
      ),
    ];

    return FoodAnalyticStatistics(
      dateRange: _formatRange(range.start, range.end),
      totalDish: 10,
      totalMeals: 15,
      charts: [
        FoodAnalyticChart(
          title: 'Most Meal Planned',
          type: FoodAnalyticChartType.mealPlanned,
          summaryTitle: 'Total Dish',
          summaryValue: 10,
          highlightTitle: 'Total Meals',
          highlightValue: '15',
          items: dishItems,
        ),
        FoodAnalyticChart(
          title: 'Most Prepared Ingredient',
          type: FoodAnalyticChartType.preparedIngredient,
          summaryTitle: 'Total Ingredient Prepared',
          summaryValue: 119,
          highlightTitle: 'Most Prepared Ingredient',
          highlightValue: 'Tomato',
          items: ingredientItems,
        ),
        FoodAnalyticChart(
          title: 'Most Category Meal Prepared',
          type: FoodAnalyticChartType.categoryMealPrepared,
          summaryTitle: 'Total Meal Planned',
          summaryValue: 61,
          highlightTitle: 'Top Planned Meal Category',
          highlightValue: 'Asian',
          items: categoryItems,
        ),
      ],
    );
  }

  Future<CaloriesIntakeStatistics> getCaloriesIntake({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final range = _resolveRange(startDate, endDate);

    return CaloriesIntakeStatistics(
      dateRange: _formatRange(range.start, range.end),
      totalMeal: 10,
      averageCaloriesKcal: 1000,
      dailyIntakes: [
        CaloriesDailyIntake(
          date: DateTime(2024, 5, 12),
          weekdayLabel: 'Mon',
          totalPlannedMeal: 1,
          totalCaloriesKcal: 180,
          totalCarbohydrateGram: 38,
          totalProteinGram: 8,
          meals: const [
            CaloriesMealItem(
              name: 'Pesto Pasta',
              caloriesKcal: 180,
              carbohydrateGram: 38,
              proteinGram: 8,
              icon: Icons.ramen_dining,
            ),
          ],
        ),
        CaloriesDailyIntake(
          date: DateTime(2024, 5, 13),
          weekdayLabel: 'Tue',
          totalPlannedMeal: 2,
          totalCaloriesKcal: 310,
          totalCarbohydrateGram: 64,
          totalProteinGram: 25,
          meals: const [
            CaloriesMealItem(
              name: 'Pesto Pasta',
              caloriesKcal: 160,
              carbohydrateGram: 34,
              proteinGram: 7,
              icon: Icons.ramen_dining,
            ),
            CaloriesMealItem(
              name: 'Chicken Bowl',
              caloriesKcal: 150,
              carbohydrateGram: 30,
              proteinGram: 18,
              icon: Icons.rice_bowl,
            ),
          ],
        ),
        CaloriesDailyIntake(
          date: DateTime(2024, 5, 14),
          weekdayLabel: 'Wed',
          totalPlannedMeal: 1,
          totalCaloriesKcal: 260,
          totalCarbohydrateGram: 50,
          totalProteinGram: 12,
          meals: const [
            CaloriesMealItem(
              name: 'Garden Wrap',
              caloriesKcal: 260,
              carbohydrateGram: 50,
              proteinGram: 12,
              icon: Icons.lunch_dining,
            ),
          ],
        ),
        CaloriesDailyIntake(
          date: DateTime(2024, 5, 15),
          weekdayLabel: 'Thu',
          totalPlannedMeal: 2,
          totalCaloriesKcal: 85,
          totalCarbohydrateGram: 18,
          totalProteinGram: 5,
          meals: const [
            CaloriesMealItem(
              name: 'Pesto Pasta',
              caloriesKcal: 45,
              carbohydrateGram: 10,
              proteinGram: 3,
              icon: Icons.ramen_dining,
            ),
            CaloriesMealItem(
              name: 'Pesto Pasta',
              caloriesKcal: 40,
              carbohydrateGram: 8,
              proteinGram: 2,
              icon: Icons.ramen_dining,
            ),
          ],
        ),
        CaloriesDailyIntake(
          date: DateTime(2024, 5, 16),
          weekdayLabel: 'Fri',
          totalPlannedMeal: 2,
          totalCaloriesKcal: 205,
          totalCarbohydrateGram: 38,
          totalProteinGram: 26,
          meals: const [
            CaloriesMealItem(
              name: 'Chicken Bowl',
              caloriesKcal: 120,
              carbohydrateGram: 22,
              proteinGram: 17,
              icon: Icons.rice_bowl,
            ),
            CaloriesMealItem(
              name: 'Soup Bowl',
              caloriesKcal: 85,
              carbohydrateGram: 16,
              proteinGram: 9,
              icon: Icons.soup_kitchen,
            ),
          ],
        ),
        CaloriesDailyIntake(
          date: DateTime(2024, 5, 17),
          weekdayLabel: 'Sat',
          totalPlannedMeal: 1,
          totalCaloriesKcal: 220,
          totalCarbohydrateGram: 28,
          totalProteinGram: 24,
          meals: const [
            CaloriesMealItem(
              name: 'Grilled Fish',
              caloriesKcal: 220,
              carbohydrateGram: 28,
              proteinGram: 24,
              icon: Icons.dinner_dining,
            ),
          ],
        ),
        CaloriesDailyIntake(
          date: DateTime(2024, 5, 18),
          weekdayLabel: 'Sun',
          totalPlannedMeal: 1,
          totalCaloriesKcal: 225,
          totalCarbohydrateGram: 46,
          totalProteinGram: 10,
          meals: const [
            CaloriesMealItem(
              name: 'Vegetable Wrap',
              caloriesKcal: 225,
              carbohydrateGram: 46,
              proteinGram: 10,
              icon: Icons.lunch_dining,
            ),
          ],
        ),
      ],
    );
  }

  Future<DifficultyMealStatistics> getDifficultyMeals({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final range = _resolveRange(startDate, endDate);

    return DifficultyMealStatistics(
      dateRange: _formatRange(range.start, range.end),
      totalPost: 24,
      averageDifficulty: 3.2,
      groups: [
        DifficultyMealGroup(
          difficulty: 1,
          recipeCount: 3,
          color: Color(0xFF21AEEA),
          meals: [
            DifficultyMealItem(
              name: 'Fruit Bowl',
              date: DateTime(2024, 5, 12),
              quantity: 1,
              icon: Icons.breakfast_dining,
            ),
            DifficultyMealItem(
              name: 'Toast Set',
              date: DateTime(2024, 5, 13),
              quantity: 1,
              icon: Icons.bakery_dining,
            ),
            DifficultyMealItem(
              name: 'Simple Salad',
              date: DateTime(2024, 5, 16),
              quantity: 1,
              icon: Icons.eco,
            ),
          ],
        ),
        DifficultyMealGroup(
          difficulty: 2,
          recipeCount: 5,
          color: Color(0xFF21AEEA),
          meals: [
            DifficultyMealItem(
              name: 'Pesto Pasta',
              date: DateTime(2024, 5, 12),
              quantity: 2,
              icon: Icons.ramen_dining,
            ),
            DifficultyMealItem(
              name: 'Chicken Wrap',
              date: DateTime(2024, 5, 14),
              quantity: 2,
              icon: Icons.lunch_dining,
            ),
            DifficultyMealItem(
              name: 'Soup Bowl',
              date: DateTime(2024, 5, 18),
              quantity: 1,
              icon: Icons.soup_kitchen,
            ),
          ],
        ),
        DifficultyMealGroup(
          difficulty: 3,
          recipeCount: 8,
          color: Color(0xFF21AEEA),
          meals: [
            DifficultyMealItem(
              name: 'Chicken Rice',
              date: DateTime(2024, 5, 13),
              quantity: 3,
              icon: Icons.rice_bowl,
            ),
            DifficultyMealItem(
              name: 'Grilled Fish',
              date: DateTime(2024, 5, 15),
              quantity: 3,
              icon: Icons.dinner_dining,
            ),
            DifficultyMealItem(
              name: 'Vegetable Curry',
              date: DateTime(2024, 5, 17),
              quantity: 2,
              icon: Icons.local_dining,
            ),
          ],
        ),
        DifficultyMealGroup(
          difficulty: 4,
          recipeCount: 6,
          color: Color(0xFF21AEEA),
          meals: [
            DifficultyMealItem(
              name: 'Lasagna',
              date: DateTime(2024, 5, 14),
              quantity: 4,
              icon: Icons.local_pizza,
            ),
            DifficultyMealItem(
              name: 'Roast Chicken',
              date: DateTime(2024, 5, 18),
              quantity: 2,
              icon: Icons.set_meal,
            ),
          ],
        ),
        DifficultyMealGroup(
          difficulty: 5,
          recipeCount: 2,
          color: Color(0xFF21AEEA),
          meals: [
            DifficultyMealItem(
              name: 'Beef Wellington',
              date: DateTime(2024, 5, 16),
              quantity: 1,
              icon: Icons.restaurant,
            ),
            DifficultyMealItem(
              name: 'Layer Cake',
              date: DateTime(2024, 5, 18),
              quantity: 1,
              icon: Icons.cake,
            ),
          ],
        ),
      ],
    );
  }

  Future<MealPlanMethodStatistics> getMealPlanMethods({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final range = _resolveRange(startDate, endDate);

    return MealPlanMethodStatistics(
      dateRange: _formatRange(range.start, range.end),
      totalMethodUsed: 15,
      topMethod: 'From Library',
      groups: [
        MealPlanMethodGroup(
          title: 'From Library',
          totalUsed: 8,
          color: const Color(0xFF10A957),
          icon: Icons.library_books,
          meals: [
            MealPlanMethodItem(
              recipeName: 'Pesto Pasta',
              date: DateTime(2024, 5, 12),
              mealTime: 'Breakfast',
              quantity: 3,
              icon: Icons.ramen_dining,
            ),
            MealPlanMethodItem(
              recipeName: 'Chicken Bowl',
              date: DateTime(2024, 5, 13),
              mealTime: 'Lunch',
              quantity: 2,
              icon: Icons.rice_bowl,
            ),
            MealPlanMethodItem(
              recipeName: 'Garden Wrap',
              date: DateTime(2024, 5, 14),
              mealTime: 'Dinner',
              quantity: 2,
              icon: Icons.lunch_dining,
            ),
            MealPlanMethodItem(
              recipeName: 'Soup Bowl',
              date: DateTime(2024, 5, 15),
              mealTime: 'Lunch',
              quantity: 1,
              icon: Icons.soup_kitchen,
            ),
          ],
        ),
        MealPlanMethodGroup(
          title: 'Generate with AI',
          totalUsed: 5,
          color: const Color(0xFFFFB300),
          icon: Icons.smart_toy_outlined,
          meals: [
            MealPlanMethodItem(
              recipeName: 'Soup Bowl',
              date: DateTime(2024, 5, 16),
              mealTime: 'Dinner',
              quantity: 2,
              icon: Icons.soup_kitchen,
            ),
            MealPlanMethodItem(
              recipeName: 'Grilled Fish',
              date: DateTime(2024, 5, 17),
              mealTime: 'Dinner',
              quantity: 2,
              icon: Icons.dinner_dining,
            ),
            MealPlanMethodItem(
              recipeName: 'Breakfast Toast',
              date: DateTime(2024, 5, 18),
              mealTime: 'Breakfast',
              quantity: 1,
              icon: Icons.breakfast_dining,
            ),
          ],
        ),
        MealPlanMethodGroup(
          title: 'Explore Community',
          totalUsed: 2,
          color: const Color(0xFFFF4D5A),
          icon: Icons.forum_outlined,
          meals: [
            MealPlanMethodItem(
              recipeName: 'Vegetable Curry',
              date: DateTime(2024, 5, 15),
              mealTime: 'Lunch',
              quantity: 1,
              icon: Icons.local_dining,
            ),
            MealPlanMethodItem(
              recipeName: 'Layer Cake',
              date: DateTime(2024, 5, 18),
              mealTime: 'Snack',
              quantity: 1,
              icon: Icons.cake,
            ),
          ],
        ),
      ],
    );
  }

  Future<PostAnalyticStatistics> getPostAnalytic({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final range = _resolveRange(startDate, endDate);

    const posts = [
      PostRatingItem(
        name: 'Pesto Pasta',
        rating: 4.8,
        ratingCount: 42,
        icon: Icons.ramen_dining,
      ),
      PostRatingItem(
        name: 'Chicken Bowl',
        rating: 4.2,
        ratingCount: 38,
        icon: Icons.rice_bowl,
      ),
      PostRatingItem(
        name: 'Garden Wrap',
        rating: 3.9,
        ratingCount: 24,
        icon: Icons.lunch_dining,
      ),
      PostRatingItem(
        name: 'Soup Bowl',
        rating: 3.4,
        ratingCount: 16,
        icon: Icons.soup_kitchen,
      ),
      PostRatingItem(
        name: 'Grilled Fish',
        rating: 4.5,
        ratingCount: 31,
        icon: Icons.dinner_dining,
      ),
    ];

    return PostAnalyticStatistics(
      dateRange: _formatRange(range.start, range.end),
      totalPost: 10,
      averageRating: 4.5,
      posts: posts,
      categories: [
        PostRatingCategory(
          name: 'Italian',
          averageRating: 4.7,
          ratedDishCount: 18,
          icon: Icons.local_pizza,
          dishes: const [
            PostRatingItem(
              name: 'Pesto Pasta',
              rating: 4.8,
              ratingCount: 12,
              icon: Icons.ramen_dining,
            ),
            PostRatingItem(
              name: 'Garden Wrap',
              rating: 4.5,
              ratingCount: 6,
              icon: Icons.lunch_dining,
            ),
          ],
        ),
        PostRatingCategory(
          name: 'Asian',
          averageRating: 4.4,
          ratedDishCount: 15,
          icon: Icons.rice_bowl,
          dishes: const [
            PostRatingItem(
              name: 'Chicken Bowl',
              rating: 4.4,
              ratingCount: 9,
              icon: Icons.rice_bowl,
            ),
            PostRatingItem(
              name: 'Grilled Fish',
              rating: 4.3,
              ratingCount: 6,
              icon: Icons.dinner_dining,
            ),
          ],
        ),
        PostRatingCategory(
          name: 'Healthy',
          averageRating: 4.1,
          ratedDishCount: 12,
          icon: Icons.eco,
          dishes: const [
            PostRatingItem(
              name: 'Garden Wrap',
              rating: 4.2,
              ratingCount: 8,
              icon: Icons.lunch_dining,
            ),
            PostRatingItem(
              name: 'Soup Bowl',
              rating: 3.9,
              ratingCount: 4,
              icon: Icons.soup_kitchen,
            ),
          ],
        ),
        PostRatingCategory(
          name: 'Dinner',
          averageRating: 3.8,
          ratedDishCount: 10,
          icon: Icons.dinner_dining,
          dishes: const [
            PostRatingItem(
              name: 'Grilled Fish',
              rating: 4.0,
              ratingCount: 6,
              icon: Icons.dinner_dining,
            ),
            PostRatingItem(
              name: 'Soup Bowl',
              rating: 3.6,
              ratingCount: 4,
              icon: Icons.soup_kitchen,
            ),
          ],
        ),
        PostRatingCategory(
          name: 'Soup',
          averageRating: 3.5,
          ratedDishCount: 8,
          icon: Icons.soup_kitchen,
          dishes: const [
            PostRatingItem(
              name: 'Soup Bowl',
              rating: 3.5,
              ratingCount: 8,
              icon: Icons.soup_kitchen,
            ),
          ],
        ),
      ],
    );
  }

  Future<CaloriesPostedStatistics> getCaloriesPosted({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final range = _resolveRange(startDate, endDate);

    return CaloriesPostedStatistics(
      dateRange: _formatRange(range.start, range.end),
      totalPost: 10,
      averageCaloriesKcal: 680,
      averageCarbohydrateGram: 76,
      averageProteinGram: 32,
      dailyPosts: [
        CaloriesPostedDay(
          date: DateTime(2024, 5, 12),
          weekdayLabel: 'Mon',
          totalPost: 1,
          totalCaloriesKcal: 520,
          totalCarbohydrateGram: 72,
          totalProteinGram: 18,
          posts: const [
            CaloriesPostedItem(
              recipeName: 'Pesto Pasta',
              caloriesKcal: 520,
              carbohydrateGram: 72,
              proteinGram: 18,
              icon: Icons.ramen_dining,
            ),
          ],
        ),
        CaloriesPostedDay(
          date: DateTime(2024, 5, 13),
          weekdayLabel: 'Tue',
          totalPost: 2,
          totalCaloriesKcal: 980,
          totalCarbohydrateGram: 101,
          totalProteinGram: 55,
          posts: const [
            CaloriesPostedItem(
              recipeName: 'Chicken Bowl',
              caloriesKcal: 460,
              carbohydrateGram: 44,
              proteinGram: 31,
              icon: Icons.rice_bowl,
            ),
            CaloriesPostedItem(
              recipeName: 'Soup Bowl',
              caloriesKcal: 520,
              carbohydrateGram: 57,
              proteinGram: 24,
              icon: Icons.soup_kitchen,
            ),
          ],
        ),
        CaloriesPostedDay(
          date: DateTime(2024, 5, 14),
          weekdayLabel: 'Wed',
          totalPost: 1,
          totalCaloriesKcal: 760,
          totalCarbohydrateGram: 96,
          totalProteinGram: 35,
          posts: const [
            CaloriesPostedItem(
              recipeName: 'Lasagna',
              caloriesKcal: 760,
              carbohydrateGram: 96,
              proteinGram: 35,
              icon: Icons.local_pizza,
            ),
          ],
        ),
        CaloriesPostedDay(
          date: DateTime(2024, 5, 15),
          weekdayLabel: 'Thu',
          totalPost: 2,
          totalCaloriesKcal: 610,
          totalCarbohydrateGram: 82,
          totalProteinGram: 22,
          posts: const [
            CaloriesPostedItem(
              recipeName: 'Garden Wrap',
              caloriesKcal: 280,
              carbohydrateGram: 46,
              proteinGram: 12,
              icon: Icons.lunch_dining,
            ),
            CaloriesPostedItem(
              recipeName: 'Fruit Bowl',
              caloriesKcal: 330,
              carbohydrateGram: 36,
              proteinGram: 10,
              icon: Icons.breakfast_dining,
            ),
          ],
        ),
        CaloriesPostedDay(
          date: DateTime(2024, 5, 16),
          weekdayLabel: 'Fri',
          totalPost: 1,
          totalCaloriesKcal: 430,
          totalCarbohydrateGram: 58,
          totalProteinGram: 15,
          posts: const [
            CaloriesPostedItem(
              recipeName: 'Simple Salad',
              caloriesKcal: 430,
              carbohydrateGram: 58,
              proteinGram: 15,
              icon: Icons.eco,
            ),
          ],
        ),
        CaloriesPostedDay(
          date: DateTime(2024, 5, 17),
          weekdayLabel: 'Sat',
          totalPost: 2,
          totalCaloriesKcal: 920,
          totalCarbohydrateGram: 96,
          totalProteinGram: 58,
          posts: const [
            CaloriesPostedItem(
              recipeName: 'Grilled Fish',
              caloriesKcal: 510,
              carbohydrateGram: 46,
              proteinGram: 36,
              icon: Icons.dinner_dining,
            ),
            CaloriesPostedItem(
              recipeName: 'Vegetable Curry',
              caloriesKcal: 410,
              carbohydrateGram: 50,
              proteinGram: 22,
              icon: Icons.local_dining,
            ),
          ],
        ),
        CaloriesPostedDay(
          date: DateTime(2024, 5, 18),
          weekdayLabel: 'Sun',
          totalPost: 1,
          totalCaloriesKcal: 540,
          totalCarbohydrateGram: 62,
          totalProteinGram: 20,
          posts: const [
            CaloriesPostedItem(
              recipeName: 'Breakfast Toast',
              caloriesKcal: 540,
              carbohydrateGram: 62,
              proteinGram: 20,
              icon: Icons.breakfast_dining,
            ),
          ],
        ),
      ],
    );
  }

  Future<PostedMealTimeStatistics> getPostedMealTime({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final range = _resolveRange(startDate, endDate);

    return PostedMealTimeStatistics(
      dateRange: _formatRange(range.start, range.end),
      totalPost: 15,
      mostPostedMealTime: 'Breakfast',
      segments: [
        PostedMealTimeSegment(
          title: 'Breakfast Meal',
          totalPosted: 8,
          color: const Color(0xFF10A957),
          icon: Icons.breakfast_dining,
          meals: [
            PostedMealTimeItem(
              recipeName: 'Pesto Pasta',
              date: DateTime(2024, 5, 12),
              quantity: 4,
              icon: Icons.ramen_dining,
            ),
            PostedMealTimeItem(
              recipeName: 'Breakfast Toast',
              date: DateTime(2024, 5, 15),
              quantity: 3,
              icon: Icons.breakfast_dining,
            ),
            PostedMealTimeItem(
              recipeName: 'Fruit Bowl',
              date: DateTime(2024, 5, 18),
              quantity: 1,
              icon: Icons.local_dining,
            ),
          ],
        ),
        PostedMealTimeSegment(
          title: 'Lunch Meal',
          totalPosted: 5,
          color: const Color(0xFFFFB300),
          icon: Icons.wb_sunny_outlined,
          meals: [
            PostedMealTimeItem(
              recipeName: 'Chicken Bowl',
              date: DateTime(2024, 5, 13),
              quantity: 2,
              icon: Icons.rice_bowl,
            ),
            PostedMealTimeItem(
              recipeName: 'Garden Wrap',
              date: DateTime(2024, 5, 16),
              quantity: 2,
              icon: Icons.lunch_dining,
            ),
            PostedMealTimeItem(
              recipeName: 'Simple Salad',
              date: DateTime(2024, 5, 17),
              quantity: 1,
              icon: Icons.eco,
            ),
          ],
        ),
        PostedMealTimeSegment(
          title: 'Dinner Meal',
          totalPosted: 2,
          color: const Color(0xFFFF4D5A),
          icon: Icons.nightlight_round,
          meals: [
            PostedMealTimeItem(
              recipeName: 'Grilled Fish',
              date: DateTime(2024, 5, 14),
              quantity: 1,
              icon: Icons.dinner_dining,
            ),
            PostedMealTimeItem(
              recipeName: 'Soup Bowl',
              date: DateTime(2024, 5, 18),
              quantity: 1,
              icon: Icons.soup_kitchen,
            ),
          ],
        ),
      ],
    );
  }

  Future<MostCookedRecipeStatistics> getMostCookedRecipes({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final range = _resolveRange(startDate, endDate);

    return MostCookedRecipeStatistics(
      dateRange: _formatRange(range.start, range.end),
      totalUsersPlanToCook: 96,
      topPlanToCook: 'Pesto Pasta',
      recipes: [
        MostCookedRecipeItem(
          dishName: 'Pesto Pasta',
          quantity: 26,
          icon: Icons.ramen_dining,
          color: const Color(0xFF21AEEA),
          plannedDates: [
            MostCookedRecipePlanDate(
              date: DateTime(2024, 5, 12),
              plannedTimes: 8,
            ),
            MostCookedRecipePlanDate(
              date: DateTime(2024, 5, 14),
              plannedTimes: 10,
            ),
            MostCookedRecipePlanDate(
              date: DateTime(2024, 5, 18),
              plannedTimes: 8,
            ),
          ],
        ),
        MostCookedRecipeItem(
          dishName: 'Chicken Bowl',
          quantity: 21,
          icon: Icons.rice_bowl,
          color: const Color(0xFF21AEEA),
          plannedDates: [
            MostCookedRecipePlanDate(
              date: DateTime(2024, 5, 13),
              plannedTimes: 9,
            ),
            MostCookedRecipePlanDate(
              date: DateTime(2024, 5, 15),
              plannedTimes: 7,
            ),
            MostCookedRecipePlanDate(
              date: DateTime(2024, 5, 17),
              plannedTimes: 5,
            ),
          ],
        ),
        MostCookedRecipeItem(
          dishName: 'Garden Wrap',
          quantity: 18,
          icon: Icons.lunch_dining,
          color: const Color(0xFF21AEEA),
          plannedDates: [
            MostCookedRecipePlanDate(
              date: DateTime(2024, 5, 12),
              plannedTimes: 5,
            ),
            MostCookedRecipePlanDate(
              date: DateTime(2024, 5, 16),
              plannedTimes: 8,
            ),
            MostCookedRecipePlanDate(
              date: DateTime(2024, 5, 18),
              plannedTimes: 5,
            ),
          ],
        ),
        MostCookedRecipeItem(
          dishName: 'Grilled Fish',
          quantity: 17,
          icon: Icons.dinner_dining,
          color: const Color(0xFF21AEEA),
          plannedDates: [
            MostCookedRecipePlanDate(
              date: DateTime(2024, 5, 13),
              plannedTimes: 6,
            ),
            MostCookedRecipePlanDate(
              date: DateTime(2024, 5, 15),
              plannedTimes: 6,
            ),
            MostCookedRecipePlanDate(
              date: DateTime(2024, 5, 17),
              plannedTimes: 5,
            ),
          ],
        ),
        MostCookedRecipeItem(
          dishName: 'Soup Bowl',
          quantity: 14,
          icon: Icons.soup_kitchen,
          color: const Color(0xFF21AEEA),
          plannedDates: [
            MostCookedRecipePlanDate(
              date: DateTime(2024, 5, 14),
              plannedTimes: 4,
            ),
            MostCookedRecipePlanDate(
              date: DateTime(2024, 5, 16),
              plannedTimes: 5,
            ),
            MostCookedRecipePlanDate(
              date: DateTime(2024, 5, 18),
              plannedTimes: 5,
            ),
          ],
        ),
      ],
    );
  }

  Future<PostDifficultyStatistics> getPostDifficulty({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final range = _resolveRange(startDate, endDate);

    return PostDifficultyStatistics(
      dateRange: _formatRange(range.start, range.end),
      totalPost: 10,
      averageDifficulty: 3.0,
      groups: [
        PostDifficultyGroup(
          difficulty: 1,
          postCount: 2,
          color: const Color(0xFF21AEEA),
          posts: [
            PostDifficultyItem(
              recipeName: 'Fruit Bowl',
              date: DateTime(2024, 5, 12),
              icon: Icons.breakfast_dining,
            ),
            PostDifficultyItem(
              recipeName: 'Simple Salad',
              date: DateTime(2024, 5, 16),
              icon: Icons.eco,
            ),
          ],
        ),
        PostDifficultyGroup(
          difficulty: 2,
          postCount: 2,
          color: const Color(0xFF21AEEA),
          posts: [
            PostDifficultyItem(
              recipeName: 'Pesto Pasta',
              date: DateTime(2024, 5, 12),
              icon: Icons.ramen_dining,
            ),
            PostDifficultyItem(
              recipeName: 'Soup Bowl',
              date: DateTime(2024, 5, 18),
              icon: Icons.soup_kitchen,
            ),
          ],
        ),
        PostDifficultyGroup(
          difficulty: 3,
          postCount: 2,
          color: const Color(0xFF21AEEA),
          posts: [
            PostDifficultyItem(
              recipeName: 'Chicken Bowl',
              date: DateTime(2024, 5, 13),
              icon: Icons.rice_bowl,
            ),
            PostDifficultyItem(
              recipeName: 'Garden Wrap',
              date: DateTime(2024, 5, 17),
              icon: Icons.lunch_dining,
            ),
          ],
        ),
        PostDifficultyGroup(
          difficulty: 4,
          postCount: 2,
          color: const Color(0xFF21AEEA),
          posts: [
            PostDifficultyItem(
              recipeName: 'Lasagna',
              date: DateTime(2024, 5, 14),
              icon: Icons.local_pizza,
            ),
            PostDifficultyItem(
              recipeName: 'Roast Chicken',
              date: DateTime(2024, 5, 18),
              icon: Icons.set_meal,
            ),
          ],
        ),
        PostDifficultyGroup(
          difficulty: 5,
          postCount: 2,
          color: const Color(0xFF21AEEA),
          posts: [
            PostDifficultyItem(
              recipeName: 'Layer Cake',
              date: DateTime(2024, 5, 15),
              icon: Icons.cake,
            ),
            PostDifficultyItem(
              recipeName: 'Beef Wellington',
              date: DateTime(2024, 5, 16),
              icon: Icons.restaurant,
            ),
          ],
        ),
      ],
    );
  }

  Future<AdminMealAnalyticStatistics> getAdminMealAnalytic({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final range = _resolveRange(startDate, endDate);

    return AdminMealAnalyticStatistics(
      dateRange: _formatRange(range.start, range.end),
      dailyPlans: _buildDailyStatistics(
        start: range.start,
        end: range.end,
        base: 74,
        step: 13,
        wave: 29,
      ),
      sections: [
        const AdminAnalyticSection(
          title: 'Most Planned Meal',
          summaryTitle: 'Total Planned',
          summaryValue: '748',
          highlightTitle: 'Top Meal',
          highlightValue: 'Pesto Pasta',
          items: [
            AdminRankedStatistic(
              label: 'Pesto Pasta',
              value: 128,
              percent: 0.34,
              icon: Icons.ramen_dining,
              color: Color(0xFF21AEEA),
            ),
            AdminRankedStatistic(
              label: 'Chicken Bowl',
              value: 104,
              percent: 0.28,
              icon: Icons.rice_bowl,
              color: Color(0xFF21AEEA),
            ),
            AdminRankedStatistic(
              label: 'Garden Wrap',
              value: 82,
              percent: 0.22,
              icon: Icons.lunch_dining,
              color: Color(0xFF21AEEA),
            ),
            AdminRankedStatistic(
              label: 'Soup Bowl',
              value: 64,
              percent: 0.17,
              icon: Icons.soup_kitchen,
              color: Color(0xFF21AEEA),
            ),
            AdminRankedStatistic(
              label: 'Grilled Fish',
              value: 57,
              percent: 0.15,
              icon: Icons.dinner_dining,
              color: Color(0xFF21AEEA),
            ),
          ],
        ),
        AdminAnalyticSection(
          title: 'Top Category Meal',
          summaryTitle: 'Total Category',
          summaryValue: '12',
          highlightTitle: 'Top Category',
          highlightValue: 'Asian',
          items: [
            AdminRankedStatistic(
              label: 'Asian',
              value: 220,
              percent: 0.38,
              icon: Icons.rice_bowl,
              color: Color(0xFF21AEEA),
            ),
            AdminRankedStatistic(
              label: 'Italian',
              value: 174,
              percent: 0.30,
              icon: Icons.local_pizza,
              color: Color(0xFF21AEEA),
            ),
            AdminRankedStatistic(
              label: 'Healthy',
              value: 132,
              percent: 0.23,
              icon: Icons.eco,
              color: Color(0xFF21AEEA),
            ),
            AdminRankedStatistic(
              label: 'Western',
              value: 96,
              percent: 0.16,
              icon: Icons.lunch_dining,
              color: Color(0xFF21AEEA),
            ),
          ],
        ),
        AdminAnalyticSection(
          title: 'Meal Planned Time',
          summaryTitle: 'Total Meals',
          summaryValue: '748',
          highlightTitle: 'Top Time',
          highlightValue: 'Dinner',
          items: [
            AdminRankedStatistic(
              label: 'Dinner',
              value: 310,
              percent: 0.41,
              icon: Icons.dinner_dining,
              color: Color(0xFF21AEEA),
            ),
            AdminRankedStatistic(
              label: 'Lunch',
              value: 248,
              percent: 0.33,
              icon: Icons.lunch_dining,
              color: Color(0xFF21AEEA),
            ),
            AdminRankedStatistic(
              label: 'Breakfast',
              value: 190,
              percent: 0.25,
              icon: Icons.breakfast_dining,
              color: Color(0xFF21AEEA),
            ),
          ],
        ),
        AdminAnalyticSection(
          title: 'Average Difficulty',
          summaryTitle: 'Average',
          summaryValue: '3.8',
          highlightTitle: 'Most Common',
          highlightValue: 'Level 3',
          items: [
            AdminRankedStatistic(
              label: 'Level 1',
              value: 62,
              percent: 0.08,
              icon: Icons.looks_one,
              color: Color(0xFF21AEEA),
            ),
            AdminRankedStatistic(
              label: 'Level 2',
              value: 134,
              percent: 0.18,
              icon: Icons.looks_two,
              color: Color(0xFF21AEEA),
            ),
            AdminRankedStatistic(
              label: 'Level 3',
              value: 266,
              percent: 0.36,
              icon: Icons.looks_3,
              color: Color(0xFF21AEEA),
            ),
            AdminRankedStatistic(
              label: 'Level 4',
              value: 204,
              percent: 0.27,
              icon: Icons.looks_4,
              color: Color(0xFF21AEEA),
            ),
            AdminRankedStatistic(
              label: 'Level 5',
              value: 82,
              percent: 0.11,
              icon: Icons.looks_5,
              color: Color(0xFF21AEEA),
            ),
          ],
        ),
        AdminAnalyticSection(
          title: 'Method Of Creating Meal Plan',
          summaryTitle: 'Total Created',
          summaryValue: '748',
          highlightTitle: 'Top Method',
          highlightValue: 'From Library',
          items: [
            AdminRankedStatistic(
              label: 'From Library',
              value: 356,
              percent: 0.48,
              icon: Icons.library_books,
              color: Color(0xFF21AEEA),
            ),
            AdminRankedStatistic(
              label: 'Generate With AI',
              value: 238,
              percent: 0.32,
              icon: Icons.smart_toy_outlined,
              color: Color(0xFF21AEEA),
            ),
            AdminRankedStatistic(
              label: 'Explore Community',
              value: 154,
              percent: 0.20,
              icon: Icons.forum_outlined,
              color: Color(0xFF21AEEA),
            ),
          ],
        ),
      ],
    );
  }

  Future<AdminPostAnalyticStatistics> getAdminPostAnalytic({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final range = _resolveRange(startDate, endDate);

    return AdminPostAnalyticStatistics(
      dateRange: _formatRange(range.start, range.end),
      dailyPosts: _buildDailyStatistics(
        start: range.start,
        end: range.end,
        base: 28,
        step: 7,
        wave: 17,
      ),
      sections: [
        const AdminAnalyticSection(
          title: 'Most Rating For All Posted',
          summaryTitle: 'Total Post',
          summaryValue: '333',
          highlightTitle: 'Top Rated',
          highlightValue: 'Grilled Fish',
          items: [
            AdminRankedStatistic(
              label: 'Grilled Fish',
              value: 49,
              percent: 0.42,
              icon: Icons.dinner_dining,
              color: Color(0xFF21AEEA),
            ),
            AdminRankedStatistic(
              label: 'Pesto Pasta',
              value: 47,
              percent: 0.40,
              icon: Icons.ramen_dining,
              color: Color(0xFF21AEEA),
            ),
            AdminRankedStatistic(
              label: 'Chicken Bowl',
              value: 42,
              percent: 0.36,
              icon: Icons.rice_bowl,
              color: Color(0xFF21AEEA),
            ),
            AdminRankedStatistic(
              label: 'Garden Wrap',
              value: 39,
              percent: 0.33,
              icon: Icons.lunch_dining,
              color: Color(0xFF21AEEA),
            ),
          ],
        ),
        AdminAnalyticSection(
          title: 'Most Rating Category',
          summaryTitle: 'Rated Category',
          summaryValue: '10',
          highlightTitle: 'Top Category',
          highlightValue: 'Italian',
          items: [
            AdminRankedStatistic(
              label: 'Italian',
              value: 48,
              percent: 0.40,
              icon: Icons.local_pizza,
              color: Color(0xFF21AEEA),
            ),
            AdminRankedStatistic(
              label: 'Asian',
              value: 44,
              percent: 0.37,
              icon: Icons.rice_bowl,
              color: Color(0xFF21AEEA),
            ),
            AdminRankedStatistic(
              label: 'Healthy',
              value: 41,
              percent: 0.34,
              icon: Icons.eco,
              color: Color(0xFF21AEEA),
            ),
          ],
        ),
        AdminAnalyticSection(
          title: 'Recipe Performance',
          summaryTitle: 'Total Post',
          summaryValue: '333',
          highlightTitle: 'Top Time',
          highlightValue: 'Dinner',
          items: [
            AdminRankedStatistic(
              label: 'Dinner',
              value: 148,
              percent: 0.44,
              icon: Icons.dinner_dining,
              color: Color(0xFF21AEEA),
            ),
            AdminRankedStatistic(
              label: 'Lunch',
              value: 112,
              percent: 0.34,
              icon: Icons.lunch_dining,
              color: Color(0xFF21AEEA),
            ),
            AdminRankedStatistic(
              label: 'Breakfast',
              value: 73,
              percent: 0.22,
              icon: Icons.breakfast_dining,
              color: Color(0xFF21AEEA),
            ),
          ],
        ),
        AdminAnalyticSection(
          title: 'Recipe That Been Planned The Most',
          summaryTitle: 'Total Planned',
          summaryValue: '612',
          highlightTitle: 'Top Recipe',
          highlightValue: 'Pesto Pasta',
          items: [
            AdminRankedStatistic(
              label: 'Pesto Pasta',
              value: 122,
              percent: 0.33,
              icon: Icons.ramen_dining,
              color: Color(0xFF21AEEA),
            ),
            AdminRankedStatistic(
              label: 'Chicken Bowl',
              value: 98,
              percent: 0.26,
              icon: Icons.rice_bowl,
              color: Color(0xFF21AEEA),
            ),
            AdminRankedStatistic(
              label: 'Garden Wrap',
              value: 81,
              percent: 0.22,
              icon: Icons.lunch_dining,
              color: Color(0xFF21AEEA),
            ),
          ],
        ),
        AdminAnalyticSection(
          title: 'Average Difficulty',
          summaryTitle: 'Average',
          summaryValue: '3.5',
          highlightTitle: 'Most Common',
          highlightValue: 'Level 4',
          items: [
            AdminRankedStatistic(
              label: 'Level 1',
              value: 18,
              percent: 0.05,
              icon: Icons.looks_one,
              color: Color(0xFF21AEEA),
            ),
            AdminRankedStatistic(
              label: 'Level 2',
              value: 54,
              percent: 0.16,
              icon: Icons.looks_two,
              color: Color(0xFF21AEEA),
            ),
            AdminRankedStatistic(
              label: 'Level 3',
              value: 98,
              percent: 0.29,
              icon: Icons.looks_3,
              color: Color(0xFF21AEEA),
            ),
            AdminRankedStatistic(
              label: 'Level 4',
              value: 112,
              percent: 0.34,
              icon: Icons.looks_4,
              color: Color(0xFF21AEEA),
            ),
            AdminRankedStatistic(
              label: 'Level 5',
              value: 51,
              percent: 0.15,
              icon: Icons.looks_5,
              color: Color(0xFF21AEEA),
            ),
          ],
        ),
      ],
    );
  }

  Future<AdminDietaryPreferenceStatistics> getAdminDietaryPreference({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final range = _resolveRange(startDate, endDate);

    return AdminDietaryPreferenceStatistics(
      dateRange: _formatRange(range.start, range.end),
      totalUsers: 420,
      topPreference: 'No Pork',
      preferences: const [
        AdminRankedStatistic(
          label: 'No Pork',
          value: 146,
          percent: 0.35,
          icon: Icons.no_food,
          color: Color(0xFF10A957),
        ),
        AdminRankedStatistic(
          label: 'No Alcohol',
          value: 118,
          percent: 0.28,
          icon: Icons.local_bar_outlined,
          color: Color(0xFFFFB300),
        ),
        AdminRankedStatistic(
          label: 'Vegetarian',
          value: 96,
          percent: 0.23,
          icon: Icons.eco,
          color: Color(0xFF21AEEA),
        ),
        AdminRankedStatistic(
          label: 'Anti Vege',
          value: 60,
          percent: 0.14,
          icon: Icons.restaurant,
          color: Color(0xFFFF4D5A),
        ),
      ],
    );
  }

  ({DateTime start, DateTime end}) _resolveRange(
    DateTime? startDate,
    DateTime? endDate,
  ) {
    final defaultStart = DateTime(2024, 5, 12);
    final defaultEnd = DateTime(2024, 5, 18);
    final start = DateUtils.dateOnly(startDate ?? defaultStart);
    final end = DateUtils.dateOnly(endDate ?? defaultEnd);
    return start.isAfter(end)
        ? (start: end, end: start)
        : (start: start, end: end);
  }

  String _formatRange(DateTime start, DateTime end) {
    final formatter = DateFormat('MMM d, yyyy');
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }

  List<AdminDailyStatistic> _buildDailyStatistics({
    required DateTime start,
    required DateTime end,
    required int base,
    required int step,
    required int wave,
  }) {
    final dayCount = end.difference(start).inDays + 1;
    return List.generate(dayCount, (index) {
      final date = start.add(Duration(days: index));
      final value =
          base + ((index * step + date.day * 3) % wave) + index % 3 * 8;
      return AdminDailyStatistic(date: date, value: value);
    });
  }
}
