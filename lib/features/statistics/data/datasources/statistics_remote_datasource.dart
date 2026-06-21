// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
import '../../domain/entities/recipe_performance_statistics.dart';
import '../../domain/entities/statistics_dashboard.dart';

// This is the main database reader for statistics.
// It collects raw Firestore data such as users, meal plans, recipes,
// grocery lists, ratings, and preferences, then turns them into report data.
// Handles StatisticsRemoteDataSource for this part of the statistics page.
class StatisticsRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  // Handles StatisticsRemoteDataSource for this part of the statistics page.
  const StatisticsRemoteDataSource({
    required this.firestore,
    required this.auth,
  });

  // Handles getUserSelfHeroSlides for this part of the statistics page.
  Future<List<StatisticsHeroSlide>> getUserSelfHeroSlides() async {
    // Get the current user's meal plans from the database so the top
    // statistics cards can show their personal meal planning progress.
    final uid = auth.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      return _buildSelfSlides(const [], createdAt: DateTime.now());
    }

    final allPlans = await _getUserMealPlans(uid, (
      start: DateTime.fromMillisecondsSinceEpoch(0),
      end: DateTime(9999, 12, 31, 23, 59, 59),
    ));
    final createdAt = await _currentUserCreatedAt(uid);
    return _buildSelfSlides(allPlans, createdAt: createdAt);
  }

  // Handles getUserCommunityHeroSlides for this part of the statistics page.
  Future<List<StatisticsHeroSlide>> getUserCommunityHeroSlides() async {
    // Get recipes posted by the current user, then build the community
    // statistics cards from those recipe records.
    final uid = auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return _buildCommunitySlides(const []);

    final recipes = await _getUserSharedRecipes(uid);
    return _buildCommunitySlides(recipes);
  }

  // Handles getAdminHeroSlides for this part of the statistics page.
  Future<List<StatisticsHeroSlide>> getAdminHeroSlides() async {
    // Admin cards look at system-wide database data, so this reads all meal
    // plans and public recipes instead of only the logged-in user's records.
    final today = _resolveRange(DateTime.now(), DateTime.now());
    final todayPlans = await _getAllMealPlans(today);
    final todayRecipes = await _getAllSharedRecipes(today);
    final allRange = (
      start: DateTime.fromMillisecondsSinceEpoch(0),
      end: DateTime(9999, 12, 31, 23, 59, 59),
    );
    final allPlans = await _getAllMealPlans(allRange);
    final allRecipes = await _getAllSharedRecipes(allRange);
    final topRatedRecipeToday = await _topRatedRecipeByRatingDate(
      recipes: allRecipes,
      range: today,
    );
    final plannedCategories = await _categoryGroups(todayPlans);
    final postedCategories = await _buildPostRatingCategories(todayRecipes);
    final averagePlannedDifficulty = todayPlans.isEmpty
        ? 0.0
        : todayPlans.fold<int>(
                0,
                (total, plan) => total + plan.difficultyLevel,
              ) /
              todayPlans.length;
    final averagePostedDifficulty = todayRecipes.isEmpty
        ? 0.0
        : todayRecipes.fold<int>(
                0,
                (total, recipe) => total + recipe.difficultyLevel,
              ) /
              todayRecipes.length;

    return [
      StatisticsHeroSlide(
        title: 'Meal Planned Today',
        type: StatisticsHeroSlideType.overview,
        metrics: [
          StatisticsMetric(
            label: 'Meal Planned Today',
            value: todayPlans.length.toString(),
            tone: StatisticsMetricTone.positive,
          ),
          StatisticsMetric(
            label: 'Average Difficulty Today',
            value: averagePlannedDifficulty.toStringAsFixed(1),
            tone: StatisticsMetricTone.neutral,
          ),
          StatisticsMetric(
            label: 'Top Meal Planned Today',
            value: _topMealName(todayPlans),
            tone: StatisticsMetricTone.positive,
          ),
          StatisticsMetric(
            label: 'Top Planned Category Today',
            value: _topFoodGroupName(plannedCategories),
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
            value: todayRecipes.length.toString(),
            tone: StatisticsMetricTone.positive,
          ),
          StatisticsMetric(
            label: 'Average Difficulty Posted',
            value: averagePostedDifficulty.toStringAsFixed(1),
            tone: StatisticsMetricTone.neutral,
          ),
          StatisticsMetric(
            label: 'Category Posted Today',
            value: postedCategories.length.toString(),
            tone: StatisticsMetricTone.positive,
          ),
          StatisticsMetric(
            label: 'Top Rating Food Today',
            value: topRatedRecipeToday,
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
            value: allPlans.length.toString(),
            tone: StatisticsMetricTone.positive,
          ),
          StatisticsMetric(
            label: 'Recipe In System',
            value: allRecipes.length.toString(),
            tone: StatisticsMetricTone.positive,
          ),
          StatisticsMetric(
            label: 'Category In System',
            value: (await _allRecipeCategoryNames(
              allRecipes,
            )).length.toString(),
            tone: StatisticsMetricTone.positive,
          ),
          StatisticsMetric(
            label: 'Post In System',
            value: allRecipes.length.toString(),
            tone: StatisticsMetricTone.positive,
          ),
        ],
      ),
    ];
  }

  // Handles getAdminMealAnalytic for this part of the statistics page.
  Future<AdminMealAnalyticStatistics> getAdminMealAnalytic({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Reads meal plan records for the selected date range and groups them
    // into admin-friendly sections like top meal, category, time, and method.
    var range = _resolveAdminRange(startDate, endDate);
    final plans = await _getAllMealPlans(range);
    final categoryConfigs = await _getMealCategoryConfigs();
    final mealTimeGroups = <String, List<_MealPlanStat>>{
      for (final category in categoryConfigs) category.name: <_MealPlanStat>[],
    };
    for (final plan in plans) {
      final label = _mealTimeLabelForPlan(plan, categoryConfigs);
      mealTimeGroups.putIfAbsent(label, () => []).add(plan);
    }

    return AdminMealAnalyticStatistics(
      dateRange: _formatRange(range.start, range.end),
      dailyPlans: _dailyPlanCounts(plans, range),
      sections: [
        _adminSectionFromGroups(
          title: 'Most Planned Meal',
          summaryTitle: 'Total Planned',
          summaryValue: plans.length.toString(),
          highlightTitle: 'Top Meal',
          groups: _groupMealPlans(
            plans,
            labelFor: (plan) => plan.recipeName,
            imageFor: (plan) => plan.imageUrl,
          ),
          iconFor: _iconForRecipe,
        ),
        _adminSectionFromGroups(
          title: 'Top Category Meal',
          summaryTitle: 'Total Category',
          summaryValue: (await _categoryGroups(plans)).length.toString(),
          highlightTitle: 'Top Category',
          groups: await _categoryGroups(plans),
          iconFor: _iconForCategory,
          useInitialMarkers: true,
        ),
        _adminSectionFromCounts(
          title: 'Meal Planned Time',
          summaryTitle: 'Total Meals',
          summaryValue: plans.length.toString(),
          highlightTitle: 'Top Time',
          counts: {
            for (final entry in mealTimeGroups.entries)
              entry.key: entry.value.length,
          },
          details: _detailsByMealTime(mealTimeGroups),
          iconFor: _mealTimeIcon,
          colorFor: _mealTimeColor,
          includeZeroValues: true,
        ),
        _adminSectionFromCounts(
          title: 'Average Difficulty',
          summaryTitle: 'Average',
          summaryValue: _averageDifficulty(plans).toStringAsFixed(1),
          highlightTitle: 'Most Common',
          counts: {
            for (var level = 1; level <= 5; level++)
              '$level Star': plans
                  .where((plan) => plan.difficultyLevel == level)
                  .length,
          },
          details: _detailsByMealDifficulty(plans),
          iconFor: _difficultyIcon,
          colorFor: _difficultyColor,
          includeZeroValues: true,
          preserveOrder: true,
        ),
        _adminSectionFromCounts(
          title: 'Method Of Creating Meal Plan',
          summaryTitle: 'Total Created',
          summaryValue: plans.length.toString(),
          highlightTitle: 'Top Method',
          counts: {
            'Explore Community': plans
                .where(
                  (plan) => _methodLabel(plan.source) == 'Explore Community',
                )
                .length,
            'From Library': plans
                .where((plan) => _methodLabel(plan.source) == 'From Library')
                .length,
            'Generate With AI': plans
                .where(
                  (plan) => _methodLabel(plan.source) == 'Generate With AI',
                )
                .length,
          },
          details: _detailsByMethod(plans),
          iconFor: _methodIcon,
          colorFor: _methodColor,
          includeZeroValues: true,
        ),
      ],
    );
  }

  // Handles getAdminPostAnalytic for this part of the statistics page.
  Future<AdminPostAnalyticStatistics> getAdminPostAnalytic({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Reads public recipe posts and related meal plans, then compares ratings,
    // views, difficulty, and how often posted recipes are planned.
    var range = _resolveAdminRange(startDate, endDate);
    final recipes = await _getAllSharedRecipes(range);
    final allPlans = await _getAllMealPlans(range);
    final allPublicRecipes = await _getAllSharedRecipes(_allTimeRange());
    final categorySection = await _adminSectionFromPostCategories(
      title: 'Most Rating Category',
      summaryTitle: 'Rated Category',
      highlightTitle: 'Top Category',
      recipes: recipes,
    );
    final recipePlanCounts = <String, int>{};
    final recipePlanImages = <String, String?>{};
    for (final plan in allPlans) {
      recipePlanCounts[plan.recipeName] =
          (recipePlanCounts[plan.recipeName] ?? 0) + 1;
      recipePlanImages[plan.recipeName] ??= plan.imageUrl;
    }

    return AdminPostAnalyticStatistics(
      dateRange: _formatRange(range.start, range.end),
      dailyPosts: _dailyPostCounts(recipes, range),
      recipePerformance: await _buildAdminRecipePerformance(allPublicRecipes),
      sections: [
        _adminSectionFromCounts(
          title: 'Most Rating For All Posted',
          summaryTitle: 'Total Post',
          summaryValue: recipes.length.toString(),
          highlightTitle: 'Top Rated',
          counts: {
            for (final recipe in recipes) recipe.name: recipe.ratingCount,
          },
          details: _detailsByRecipes(recipes),
          imageUrls: {
            for (final recipe in recipes) recipe.name: recipe.imageUrl,
          },
          iconFor: _iconForRecipe,
        ),
        categorySection,
        _adminSectionFromCounts(
          title: 'Recipe Performance',
          summaryTitle: 'Total Views',
          summaryValue: recipes
              .fold<int>(0, (total, recipe) => total + recipe.totalViews)
              .toString(),
          highlightTitle: 'Top Recipe',
          counts: {
            for (final recipe in recipes) recipe.name: recipe.totalViews,
          },
          details: _detailsByRecipes(recipes),
          imageUrls: {
            for (final recipe in recipes) recipe.name: recipe.imageUrl,
          },
          iconFor: _iconForRecipe,
        ),
        _adminSectionFromCounts(
          title: 'Recipe That Been Planned The Most',
          summaryTitle: 'Total Planned',
          summaryValue: allPlans.length.toString(),
          highlightTitle: 'Top Recipe',
          counts: recipePlanCounts,
          details: _detailsByRecipeName(allPlans),
          imageUrls: recipePlanImages,
          iconFor: _iconForRecipe,
        ),
        _adminSectionFromCounts(
          title: 'Average Difficulty',
          summaryTitle: 'Average',
          summaryValue: _averagePostDifficulty(recipes).toStringAsFixed(1),
          highlightTitle: 'Most Common',
          counts: {
            for (var level = 1; level <= 5; level++)
              '$level Star': recipes
                  .where((recipe) => recipe.difficultyLevel == level)
                  .length,
          },
          details: _detailsByPostDifficulty(recipes),
          iconFor: _difficultyIcon,
          colorFor: _difficultyColor,
          includeZeroValues: true,
          preserveOrder: true,
        ),
      ],
    );
  }

  // Handles getAdminDietaryPreference for this part of the statistics page.
  Future<AdminDietaryPreferenceStatistics> getAdminDietaryPreference({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Reads every normal user's food profile from Firestore and counts diets,
    // allergies, and dislikes so admins can see common dietary needs.
    var range = _resolveAdminRange(startDate, endDate);
    final users = await firestore.collection('users').get();
    final counts = <String, int>{};
    var totalUsers = 0;
    for (final user in users.docs) {
      if (_isAdminUser(user.data())) continue;
      final createdAt = _dateTime(user.data()['createdAt']);
      if (createdAt.isBefore(range.start) || createdAt.isAfter(range.end)) {
        continue;
      }
      totalUsers += 1;
      final profile = await user.reference
          .collection('preferences')
          .doc('food_profile')
          .get();
      final data = profile.data() ?? const <String, dynamic>{};
      final diet = _stringValue(data['diet'], fallback: 'No specific diet');
      counts[diet] = (counts[diet] ?? 0) + 1;
      for (final allergy in _stringList(data['allergies'])) {
        counts[allergy] = (counts[allergy] ?? 0) + 1;
      }
      for (final dislike in _stringList(data['dislikes'])) {
        counts[dislike] = (counts[dislike] ?? 0) + 1;
      }
    }

    final items = _rankedStatsFromCounts(
      counts: counts,
      total: totalUsers == 0 ? 1 : totalUsers,
      iconFor: _dietaryIcon,
      markerTexts: {for (final key in counts.keys) key: key},
      colors: const [
        Color(0xFF10A957),
        Color(0xFFFFB300),
        Color(0xFF21AEEA),
        Color(0xFFFF4D5A),
        Color(0xFF8E7CF3),
      ],
    );

    return AdminDietaryPreferenceStatistics(
      dateRange: _formatRange(range.start, range.end),
      totalUsers: totalUsers,
      topPreference: items.isEmpty ? '-' : items.first.label,
      preferences: items,
    );
  }

  // Handles getAdminGender for this part of the statistics page.
  Future<AdminGenderStatistics> getAdminGender({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Checks user profile records and counts gender choices for users created
    // inside the selected date range.
    var range = _resolveAdminRange(startDate, endDate);
    final users = await firestore.collection('users').get();
    final userDocs = users.docs
        .where((user) => !_isAdminUser(user.data()))
        .toList();
    final counts = <String, int>{
      'Male': 0,
      'Female': 0,
      'Prefer not to say': 0,
    };
    var totalUsers = 0;
    for (final user in userDocs) {
      final data = user.data();
      final createdAt = _dateTime(data['createdAt']);
      if (createdAt.isBefore(range.start) || createdAt.isAfter(range.end)) {
        continue;
      }
      totalUsers += 1;
      final gender = _genderLabel(data['gender']);
      counts[gender] = (counts[gender] ?? 0) + 1;
    }

    final items = _rankedStatsFromCounts(
      counts: counts,
      total: totalUsers == 0 ? 1 : totalUsers,
      iconFor: _genderIcon,
      colorFor: _genderColor,
      includeZeroValues: true,
      preserveOrder: true,
    );

    final nonZeroItems = items.where((item) => item.value > 0).toList();
    return AdminGenderStatistics(
      dateRange: _formatRange(range.start, range.end),
      totalUsers: totalUsers,
      mostGender: nonZeroItems.isEmpty ? '-' : nonZeroItems.first.label,
      genders: items,
    );
  }

  // Handles getAdminUserUsage for this part of the statistics page.
  Future<AdminUserUsageStatistics> getAdminUserUsage({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Counts user account creation dates from the users collection to show
    // how many new users joined each month.
    var range = _resolveAdminRange(startDate, endDate);
    final users = await firestore.collection('users').get();
    final createdDates = users.docs
        .where((user) => !_isAdminUser(user.data()))
        .map((user) => _dateTime(user.data()['createdAt']))
        .where((date) => date.millisecondsSinceEpoch > 0)
        .toList();
    final monthlyUsers = _monthsInRange(range).map((month) {
      final count = createdDates.where((date) {
        final userMonth = _startOfMonth(date);
        return userMonth.year == month.year && userMonth.month == month.month;
      }).length;
      return AdminMonthlyUserStatistic(month: month, newUsers: count);
    }).toList();
    final topMonth = [...monthlyUsers]
      ..sort((left, right) => right.newUsers.compareTo(left.newUsers));

    return AdminUserUsageStatistics(
      dateRange: _formatRange(range.start, range.end),
      totalUsers: monthlyUsers.fold<int>(
        0,
        (total, month) => total + month.newUsers,
      ),
      topMonth: topMonth.isEmpty || topMonth.first.newUsers == 0
          ? '-'
          : _monthYearLabel(topMonth.first.month),
      monthlyUsers: monthlyUsers,
    );
  }

  // Handles getAdminUsageForecast for this part of the statistics page.
  Future<AdminUserUsageStatistics> getAdminUsageForecast({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final statistics = await getAdminUserUsage(
      startDate: startDate,
      endDate: endDate,
    );
    final predictedMonth = _nextMonthForForecast(statistics.monthlyUsers);
    final predictedUsers = _predictedNextMonthUsers(statistics.monthlyUsers);
    final forecastMonths = [
      ...statistics.monthlyUsers,
      AdminMonthlyUserStatistic(
        month: predictedMonth,
        newUsers: predictedUsers,
        isPrediction: true,
      ),
    ];

    return AdminUserUsageStatistics(
      dateRange: statistics.dateRange,
      totalUsers: statistics.totalUsers,
      topMonth: '$predictedUsers next month',
      monthlyUsers: forecastMonths,
    );
  }

  // Handles getAdminNutrientInsight for this part of the statistics page.
  Future<CaloriesIntakeStatistics> getAdminNutrientInsight({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final range = _resolveAdminRange(startDate, endDate);
    final plannedRecipes = await _getAllPlannedRecipeNutrition(range);

    return _buildCaloriesIntakeStatistics(
      recipes: plannedRecipes,
      range: range,
    );
  }

  // Handles getAdminHubRating for this part of the statistics page.
  Future<AdminHubRatingStatistics> getAdminHubRating({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Reads app-rating feedback stored in the support center collection and
    // turns the star ratings into a monthly admin report.
    var range = _resolveAdminRange(startDate, endDate);
    final nonAdminUserIds = await _nonAdminUserIds();
    final ratings = await firestore
        .collection('support_center')
        .doc('app_rating_feedback')
        .collection('items')
        .get();
    final ratingRows = ratings.docs
        .map((doc) {
          final data = doc.data();
          final uid = _stringValue(data['uid'], fallback: doc.id);
          return (
            uid: uid,
            stars: _intValue(data['stars']).clamp(0, 5).toInt(),
            date: _dateTime(data['createdAt'] ?? data['updatedAt']),
          );
        })
        .where(
          (rating) =>
              rating.stars > 0 &&
              rating.date.millisecondsSinceEpoch > 0 &&
              (rating.uid.isEmpty || nonAdminUserIds.contains(rating.uid)),
        )
        .toList();
    final monthlyRatings = _monthsInRange(range).map((month) {
      final monthRatings = ratingRows.where((rating) {
        final ratingMonth = _startOfMonth(rating.date);
        return ratingMonth.year == month.year &&
            ratingMonth.month == month.month;
      }).toList();
      final totalStars = monthRatings.fold<int>(
        0,
        (total, rating) => total + rating.stars,
      );
      return AdminMonthlyRatingStatistic(
        month: month,
        ratingCount: monthRatings.length,
        averageRating: monthRatings.isEmpty
            ? 0
            : totalStars / monthRatings.length,
      );
    }).toList();
    final totalRatings = monthlyRatings.fold<int>(
      0,
      (total, month) => total + month.ratingCount,
    );
    final totalStars = monthlyRatings.fold<double>(
      0,
      (total, month) => total + (month.averageRating * month.ratingCount),
    );

    return AdminHubRatingStatistics(
      dateRange: _formatRange(range.start, range.end),
      totalRatings: totalRatings,
      averageRating: totalRatings == 0 ? 0 : totalStars / totalRatings,
      monthlyRatings: monthlyRatings,
    );
  }

  // Handles getUserPostAnalytic for this part of the statistics page.
  Future<PostAnalyticStatistics> getUserPostAnalytic({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Reads the current user's shared recipes and counts post activity such
    // as ratings, comments, and total engagement.
    final range = _resolveRange(startDate, endDate);
    final uid = auth.currentUser?.uid ?? '';
    final recipes = uid.isEmpty
        ? <_CommunityRecipeStat>[]
        : (await _getUserSharedRecipes(uid))
              .where(
                (recipe) =>
                    !recipe.publishedAt.isBefore(range.start) &&
                    !recipe.publishedAt.isAfter(range.end),
              )
              .toList();
    final averageRating = _averagePostedRecipeRating(recipes);
    final posts = recipes
        .map(
          (recipe) => PostRatingItem(
            id: recipe.id,
            name: recipe.name,
            rating: recipe.averageRating,
            ratingCount: recipe.ratingCount,
            icon: _iconForRecipe(recipe.name),
            imageUrl: recipe.imageUrl,
          ),
        )
        .toList();
    final categories = await _buildPostRatingCategories(recipes);

    return PostAnalyticStatistics(
      dateRange: _formatRange(range.start, range.end),
      totalPost: recipes.length,
      averageRating: averageRating,
      posts: posts,
      categories: categories,
    );
  }

  // Handles getUserPostDifficulty for this part of the statistics page.
  Future<PostDifficultyStatistics> getUserPostDifficulty({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Reads the user's posted recipes and groups them by difficulty level.
    final range = _resolveRange(startDate, endDate);
    final uid = auth.currentUser?.uid ?? '';
    final recipes = uid.isEmpty
        ? <_CommunityRecipeStat>[]
        : (await _getUserSharedRecipes(uid))
              .where(
                (recipe) =>
                    !recipe.publishedAt.isBefore(range.start) &&
                    !recipe.publishedAt.isAfter(range.end),
              )
              .toList();
    final totalDifficulty = recipes.fold<int>(
      0,
      (total, recipe) => total + recipe.difficultyLevel,
    );
    final averageDifficulty = recipes.isEmpty
        ? 0.0
        : totalDifficulty / recipes.length;

    return PostDifficultyStatistics(
      dateRange: _formatRange(range.start, range.end),
      totalPost: recipes.length,
      averageDifficulty: averageDifficulty,
      groups: List.generate(5, (index) {
        final difficulty = index + 1;
        final posts =
            recipes
                .where((recipe) => recipe.difficultyLevel == difficulty)
                .map(
                  (recipe) => PostDifficultyItem(
                    recipeName: recipe.name,
                    date: recipe.publishedAt,
                    icon: _iconForRecipe(recipe.name),
                    imageUrl: recipe.imageUrl,
                  ),
                )
                .toList()
              ..sort((left, right) => right.date.compareTo(left.date));

        return PostDifficultyGroup(
          difficulty: difficulty,
          postCount: posts.length,
          color: const Color(0xFF21AEEA),
          posts: posts,
        );
      }),
    );
  }

  // Handles getUserRecipePerformance for this part of the statistics page.
  Future<RecipePerformanceStatistics> getUserRecipePerformance() async {
    // Reads the user's public recipes and compares views, ratings, and
    // comments so the creator can see which recipe performs best.
    final uid = auth.currentUser?.uid ?? '';
    final recipes = uid.isEmpty
        ? <_CommunityRecipeStat>[]
        : await _getUserSharedRecipes(uid);
    final totalViews = recipes.fold<int>(
      0,
      (total, recipe) => total + recipe.totalViews,
    );
    final totalComments = recipes.fold<int>(
      0,
      (total, recipe) => total + recipe.commentCount,
    );
    final totalRatings = recipes.fold<int>(
      0,
      (total, recipe) => total + recipe.ratingCount,
    );
    final items = <RecipePerformanceItem>[];

    for (final recipe in recipes) {
      final favouriteCount = await _recipeFavouriteCount(recipe.id);
      items.add(
        RecipePerformanceItem(
          id: recipe.id,
          name: recipe.name,
          imageUrl: recipe.imageUrl,
          totalViews: recipe.totalViews,
          commentCount: recipe.commentCount,
          favouriteCount: favouriteCount,
          ratingCount: recipe.ratingCount,
          publishedAt: recipe.publishedAt,
        ),
      );
    }

    return RecipePerformanceStatistics(
      dateRange: 'Not available',
      totalViews: totalViews,
      totalComments: totalComments,
      totalFavourites: items.fold<int>(
        0,
        (total, recipe) => total + recipe.favouriteCount,
      ),
      totalRatings: totalRatings,
      recipes: items
        ..sort((left, right) => right.totalViews.compareTo(left.totalViews)),
    );
  }

  // Handles _recipeFavouriteCount for this part of the statistics page.
  Future<int> _recipeFavouriteCount(String recipeId) async {
    if (recipeId.trim().isEmpty) return 0;
    final favouritedUserIds = <String>{};

    try {
      final usersSnapshot = await firestore.collection('users').get();
      for (final userDoc in usersSnapshot.docs) {
        final data = userDoc.data();
        if (_hasRecipeInSavedArrays(data, recipeId)) {
          favouritedUserIds.add(userDoc.id);
          continue;
        }

        final savedDoc = await userDoc.reference
            .collection('saved_recipes')
            .doc(recipeId)
            .get();
        if (savedDoc.exists) {
          favouritedUserIds.add(userDoc.id);
          continue;
        }

        final savedSnapshot = await userDoc.reference
            .collection('saved_recipes')
            .get();
        final hasSavedRecipe = savedSnapshot.docs.any((doc) {
          final savedRecipeId = _stringValue(
            doc.data()['recipeId'] ??
                doc.data()['recipe_id'] ??
                doc.data()['recipeID'],
            fallback: doc.id,
          );
          return savedRecipeId == recipeId;
        });
        if (hasSavedRecipe) favouritedUserIds.add(userDoc.id);
      }
      return favouritedUserIds.length;
    } on FirebaseException {
      return _currentUserFavouriteCount(recipeId);
    }
  }

  // Handles _hasRecipeInSavedArrays for this part of the statistics page.
  bool _hasRecipeInSavedArrays(Map<String, dynamic> data, String recipeId) {
    for (final field in const [
      'bookmarkedRecipeIds',
      'followingRecipeIds',
      'savedRecipeIds',
      'favoriteRecipeIds',
      'favouriteRecipeIds',
    ]) {
      final value = data[field];
      if (value is Iterable &&
          value.map((item) => item.toString().trim()).contains(recipeId)) {
        return true;
      }
    }
    return false;
  }

  // Handles _currentUserFavouriteCount for this part of the statistics page.
  Future<int> _currentUserFavouriteCount(String recipeId) async {
    final uid = auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return 0;
    final doc = await firestore
        .collection('users')
        .doc(uid)
        .collection('saved_recipes')
        .doc(recipeId)
        .get();
    return doc.exists ? 1 : 0;
  }

  // Handles getUserFoodAnalytic for this part of the statistics page.
  Future<FoodAnalyticStatistics> getUserFoodAnalytic({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Reads the user's meal plans and groups the planned recipes by food,
    // ingredient, and category for the food analytics charts.
    final range = _resolveRange(startDate, endDate);
    final uid = auth.currentUser?.uid ?? '';
    final plans = uid.isEmpty
        ? <_MealPlanStat>[]
        : await _getUserMealPlans(uid, range);
    final uniqueDishCount = plans.map((plan) => plan.recipeId).toSet().length;
    final totalMeals = plans.length;

    final dishItems = _barItemsFromGroups(
      groups: _groupMealPlans(
        plans,
        labelFor: (plan) => plan.recipeName,
        imageFor: (plan) => plan.imageUrl,
      ),
      total: totalMeals,
      iconFor: _iconForRecipe,
    );
    final ingredientItems = _barItemsFromGroups(
      groups: await _ingredientGroups(plans),
      total: totalMeals,
      iconFor: (_) => Icons.eco,
      showTextFallback: true,
    );
    final categoryItems = _barItemsFromGroups(
      groups: await _categoryGroups(plans),
      total: totalMeals,
      iconFor: _iconForCategory,
      showTextFallback: true,
    );

    return FoodAnalyticStatistics(
      dateRange: _formatRange(range.start, range.end),
      totalDish: uniqueDishCount,
      totalMeals: totalMeals,
      charts: [
        _foodChart(
          title: 'Meal Planned Vs Dish',
          type: FoodAnalyticChartType.mealPlanned,
          summaryTitle: 'Total Dish',
          summaryValue: uniqueDishCount,
          highlightTitle: 'Top Dish',
          items: dishItems,
        ),
        _foodChart(
          title: 'Most Prepared Ingredient',
          type: FoodAnalyticChartType.preparedIngredient,
          summaryTitle: 'Total Meal',
          summaryValue: totalMeals,
          highlightTitle: 'Top Ingredient',
          items: ingredientItems,
        ),
        _foodChart(
          title: 'Most Category Planned',
          type: FoodAnalyticChartType.categoryMealPrepared,
          summaryTitle: 'Total Meal',
          summaryValue: totalMeals,
          highlightTitle: 'Top Category',
          items: categoryItems,
        ),
      ],
    );
  }

  // Handles getUserMealPlannedTime for this part of the statistics page.
  Future<MealPlannedTimeStatistics> getUserMealPlannedTime({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Reads meal plans and counts which meal time is used most, like
    // breakfast, lunch, dinner, or snack.
    final range = _resolveRange(startDate, endDate);
    final uid = auth.currentUser?.uid ?? '';
    final plans = uid.isEmpty
        ? <_MealPlanStat>[]
        : await _getUserMealPlans(uid, range);
    final categoryConfigs = await _getMealCategoryConfigs();
    final groups = <String, List<_MealPlanStat>>{
      for (final category in categoryConfigs) category.name: <_MealPlanStat>[],
    };
    for (final plan in plans) {
      final mealTime = _mealTimeLabelForPlan(plan, categoryConfigs);
      groups.putIfAbsent(mealTime, () => []).add(plan);
    }

    final segments =
        groups.entries.map((entry) {
          final meals = entry.value;
          final recipeGroups = <String, List<_MealPlanStat>>{};
          for (final meal in meals) {
            recipeGroups.putIfAbsent(meal.recipeId, () => []).add(meal);
          }
          return MealPlannedTimeSegment(
            title: entry.key,
            totalTaken: meals.length,
            color: _mealTimeColor(entry.key),
            icon: _mealTimeIcon(entry.key),
            meals:
                recipeGroups.values.map((sameRecipeMeals) {
                    final meal = sameRecipeMeals.first;
                    return MealPlannedItem(
                      name: meal.recipeName,
                      amount: sameRecipeMeals.length,
                      plannedDate: meal.date,
                      icon: _iconForRecipe(meal.recipeName),
                      imageUrl: meal.imageUrl,
                    );
                  }).toList()
                  ..sort((left, right) => right.amount.compareTo(left.amount)),
          );
        }).toList()..sort(
          (left, right) => right.totalTaken.compareTo(left.totalTaken),
        );

    return MealPlannedTimeStatistics(
      dateRange: _formatRange(range.start, range.end),
      totalDays: groups.length,
      totalMeals: plans.length,
      segments: segments,
    );
  }

  // Handles getUserCookingTime for this part of the statistics page.
  Future<CookingTimeStatistics> getUserCookingTime({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final range = _resolveRange(startDate, endDate);
    final uid = auth.currentUser?.uid ?? '';
    final plans = uid.isEmpty
        ? <_MealPlanStat>[]
        : await _getUserMealPlans(uid, range);
    final grouped = <DateTime, List<_MealPlanStat>>{};
    for (final plan in plans) {
      final day = _startOfDay(plan.date);
      grouped.putIfAbsent(day, () => []).add(plan);
    }

    final days = _daysInRange(range).map((date) {
      final plansForDay = grouped[date] ?? const <_MealPlanStat>[];
      final recipeGroups = <String, List<_MealPlanStat>>{};
      for (final plan in plansForDay) {
        recipeGroups.putIfAbsent(plan.recipeId, () => []).add(plan);
      }
      final meals =
          recipeGroups.values.map((sameRecipePlans) {
              final plan = sameRecipePlans.first;
              return CookingTimeMeal(
                name: plan.recipeName,
                cookingMinutes: plan.cookingTimeMinutes,
                quantity: sameRecipePlans.length,
                icon: _iconForRecipe(plan.recipeName),
                imageUrl: plan.imageUrl,
              );
            }).toList()
            ..sort((left, right) => right.quantity.compareTo(left.quantity));
      final totalCookingMinutes = meals.fold<int>(
        0,
        (total, meal) => total + (meal.cookingMinutes * meal.quantity),
      );
      return CookingTimeDay(
        date: date,
        label: DateFormat('MMM d').format(date),
        totalMeals: plansForDay.length,
        totalCookingMinutes: totalCookingMinutes,
        meals: meals,
      );
    }).toList();

    return CookingTimeStatistics(
      dateRange: _formatRange(range.start, range.end),
      totalMealPlanned: plans.length,
      totalCookingMinutes: days.fold<int>(
        0,
        (total, day) => total + day.totalCookingMinutes,
      ),
      days: days,
    );
  }

  // Handles getUserGroceryLists for this part of the statistics page.
  Future<GroceryListStatistics> getUserGroceryLists({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Reads grocery lists stored under the current user and counts how many
    // lists were created in each month.
    final range = _resolveRange(startDate, endDate);
    final uid = auth.currentUser?.uid ?? '';
    final monthKeys = _monthsInRange(
      range,
    ).map((month) => '${month.year}-${month.month}').toSet();
    final docs = uid.isEmpty
        ? <QueryDocumentSnapshot<Map<String, dynamic>>>[]
        : (await firestore
                  .collection('grocery_lists')
                  .where('uid', isEqualTo: uid)
                  .get())
              .docs;
    final grouped = <DateTime, List<GroceryListStatisticItem>>{};

    for (final doc in docs) {
      final data = doc.data();
      if (data['type']?.toString() == 'weekly') continue;
      final createdAt = _dateTime(data['createdAt']);
      if (createdAt.millisecondsSinceEpoch <= 0) continue;
      final month = _startOfMonth(createdAt);
      if (!monthKeys.contains('${month.year}-${month.month}')) continue;
      final rawName =
          data['name']?.toString().trim() ?? data['title']?.toString().trim();
      grouped
          .putIfAbsent(month, () => [])
          .add(
            GroceryListStatisticItem(
              name: rawName == null || rawName.isEmpty
                  ? 'Grocery List'
                  : rawName,
              duration: _formatGroceryListDuration(data),
              createdAt: createdAt,
            ),
          );
    }

    final months = _monthsInRange(range).map((month) {
      final lists = grouped[month] ?? <GroceryListStatisticItem>[];
      lists.sort((left, right) => right.createdAt.compareTo(left.createdAt));
      return GroceryListMonthStatistic(
        month: month,
        label: _monthYearLabel(month),
        totalLists: lists.length,
        lists: lists,
      );
    }).toList();
    final totalLists = months.fold<int>(
      0,
      (total, month) => total + month.totalLists,
    );
    final topMonths = [...months]
      ..sort((left, right) => right.totalLists.compareTo(left.totalLists));
    final topMonth = topMonths.isEmpty || topMonths.first.totalLists == 0
        ? '-'
        : topMonths.first.label;

    return GroceryListStatistics(
      dateRange: _formatRange(range.start, range.end),
      totalGroceryLists: totalLists,
      mostGroceryListMonth: topMonth,
      months: months,
    );
  }

  // Handles getUserDifficultyMeals for this part of the statistics page.
  Future<DifficultyMealStatistics> getUserDifficultyMeals({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Reads planned meals and counts their difficulty levels from 1 to 5.
    final range = _resolveRange(startDate, endDate);
    final uid = auth.currentUser?.uid ?? '';
    final plans = uid.isEmpty
        ? <_MealPlanStat>[]
        : await _getUserMealPlans(uid, range);
    final average = plans.isEmpty
        ? 0.0
        : plans.fold<int>(0, (total, plan) => total + plan.difficultyLevel) /
              plans.length;

    return DifficultyMealStatistics(
      dateRange: _formatRange(range.start, range.end),
      totalPost: plans.length,
      averageDifficulty: average,
      groups: List.generate(5, (index) {
        final difficulty = index + 1;
        final meals =
            plans
                .where((plan) => plan.difficultyLevel == difficulty)
                .map(
                  (plan) => DifficultyMealItem(
                    name: plan.recipeName,
                    date: plan.date,
                    quantity: 1,
                    icon: _iconForRecipe(plan.recipeName),
                    imageUrl: plan.imageUrl,
                  ),
                )
                .toList()
              ..sort((left, right) => right.date.compareTo(left.date));
        return DifficultyMealGroup(
          difficulty: difficulty,
          recipeCount: meals.length,
          color: const Color(0xFF21AEEA),
          meals: meals,
        );
      }),
    );
  }

  // Handles getUserMealPlanMethods for this part of the statistics page.
  Future<MealPlanMethodStatistics> getUserMealPlanMethods({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Reads the source saved with each meal plan, then shows whether meals
    // came from Explore, Library, AI generation, or another method.
    final range = _resolveRange(startDate, endDate);
    final uid = auth.currentUser?.uid ?? '';
    final plans = uid.isEmpty
        ? <_MealPlanStat>[]
        : await _getUserMealPlans(uid, range);
    final grouped = <String, List<_MealPlanStat>>{
      'Explore Community': <_MealPlanStat>[],
      'From Library': <_MealPlanStat>[],
      'Generate With AI': <_MealPlanStat>[],
    };
    for (final plan in plans) {
      grouped.putIfAbsent(_methodLabel(plan.source), () => []).add(plan);
    }
    final groups =
        grouped.entries.map((entry) {
            return MealPlanMethodGroup(
              title: entry.key,
              totalUsed: entry.value.length,
              color: _methodColor(entry.key),
              icon: _methodIcon(entry.key),
              meals: entry.value
                  .map(
                    (plan) => MealPlanMethodItem(
                      recipeName: plan.recipeName,
                      date: plan.date,
                      mealTime: plan.mealCategoryName,
                      quantity: 1,
                      icon: _iconForRecipe(plan.recipeName),
                      imageUrl: plan.imageUrl,
                    ),
                  )
                  .toList(),
            );
          }).toList()
          ..sort((left, right) => right.totalUsed.compareTo(left.totalUsed));

    return MealPlanMethodStatistics(
      dateRange: _formatRange(range.start, range.end),
      totalMethodUsed: plans.length,
      topMethod: groups.isEmpty ? '-' : groups.first.title,
      groups: groups,
    );
  }

  // Handles getUserMostCookedRecipes for this part of the statistics page.
  Future<MostCookedRecipeStatistics> getUserMostCookedRecipes({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Reads meal plans connected to the user's own recipes, then counts which
    // recipe other users planned to cook the most.
    final range = _resolveRange(startDate, endDate);
    final uid = auth.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      return MostCookedRecipeStatistics(
        dateRange: _formatRange(range.start, range.end),
        totalUsersPlanToCook: 0,
        topPlanToCook: '-',
        recipes: const [],
        days: _emptyMostCookedDays(range),
      );
    }

    final ownRecipes = await _getUserOwnedRecipes(uid);
    final ownRecipeIds = ownRecipes.map((recipe) => recipe.id).toSet();
    if (ownRecipeIds.isEmpty) {
      return MostCookedRecipeStatistics(
        dateRange: _formatRange(range.start, range.end),
        totalUsersPlanToCook: 0,
        topPlanToCook: '-',
        recipes: const [],
        days: _emptyMostCookedDays(range),
      );
    }

    final snapshot = await firestore.collection('meal_plans').get();
    final grouped = <String, _MostCookedGroup>{};
    final groupedByDay = <DateTime, Map<String, _MostCookedGroup>>{};

    for (final doc in snapshot.docs) {
      final plan = await _mealPlanStatFromDoc(doc);
      if (plan.plannerUid == uid) continue;
      if (!ownRecipeIds.contains(plan.recipeId)) continue;
      if (plan.date.isBefore(range.start) || plan.date.isAfter(range.end)) {
        continue;
      }

      final group = grouped.putIfAbsent(
        plan.recipeId,
        () => _MostCookedGroup(
          recipeName: plan.recipeName,
          imageUrl: plan.imageUrl,
        ),
      );
      group.quantity += 1;
      final day = _startOfDay(plan.date);
      group.plannedByDay[day] = (group.plannedByDay[day] ?? 0) + 1;
      final dailyGroup = groupedByDay
          .putIfAbsent(day, () => <String, _MostCookedGroup>{})
          .putIfAbsent(
            plan.recipeId,
            () => _MostCookedGroup(
              recipeName: plan.recipeName,
              imageUrl: plan.imageUrl,
            ),
          );
      dailyGroup.quantity += 1;
    }

    final colors = const [
      Color(0xFF21AEEA),
      Color(0xFF54C27A),
      Color(0xFFFFB300),
      Color(0xFFFF7A59),
      Color(0xFF8E7CF3),
    ];
    final recipes = grouped.values.toList()
      ..sort((left, right) => right.quantity.compareTo(left.quantity));

    final items = List.generate(recipes.length, (index) {
      final recipe = recipes[index];
      final dates =
          recipe.plannedByDay.entries
              .map(
                (entry) => MostCookedRecipePlanDate(
                  date: entry.key,
                  plannedTimes: entry.value,
                ),
              )
              .toList()
            ..sort((left, right) => left.date.compareTo(right.date));
      return MostCookedRecipeItem(
        dishName: recipe.recipeName,
        quantity: recipe.quantity,
        icon: _iconForRecipe(recipe.recipeName),
        color: colors[index % colors.length],
        imageUrl: recipe.imageUrl,
        plannedDates: dates,
      );
    });
    final days = _daysInRange(range).map((day) {
      final dailyRecipes =
          (groupedByDay[day]?.values.toList() ?? <_MostCookedGroup>[])
            ..sort((left, right) => right.quantity.compareTo(left.quantity));
      return MostCookedRecipeDay(
        date: day,
        totalQuantity: dailyRecipes.fold<int>(
          0,
          (total, recipe) => total + recipe.quantity,
        ),
        recipes: dailyRecipes
            .map(
              (recipe) => MostCookedRecipeDayItem(
                dishName: recipe.recipeName,
                quantity: recipe.quantity,
                icon: _iconForRecipe(recipe.recipeName),
                imageUrl: recipe.imageUrl,
              ),
            )
            .toList(),
      );
    }).toList();

    return MostCookedRecipeStatistics(
      dateRange: _formatRange(range.start, range.end),
      totalUsersPlanToCook: items.fold<int>(
        0,
        (total, recipe) => total + recipe.quantity,
      ),
      topPlanToCook: items.isEmpty ? '-' : items.first.dishName,
      recipes: items,
      days: days,
    );
  }

  // Handles _foodChart for this part of the statistics page.
  FoodAnalyticChart _foodChart({
    required String title,
    required FoodAnalyticChartType type,
    required String summaryTitle,
    required int summaryValue,
    required String highlightTitle,
    required List<FoodAnalyticBarItem> items,
  }) {
    final sorted = [...items]
      ..sort((left, right) => right.value.compareTo(left.value));
    return FoodAnalyticChart(
      title: title,
      type: type,
      summaryTitle: summaryTitle,
      summaryValue: summaryValue,
      highlightTitle: highlightTitle,
      highlightValue: sorted.isEmpty ? '-' : sorted.first.label,
      items: sorted,
    );
  }

  // Handles _groupMealPlans for this part of the statistics page.
  Map<String, _FoodGroup> _groupMealPlans(
    List<_MealPlanStat> plans, {
    required String Function(_MealPlanStat plan) labelFor,
    String? Function(_MealPlanStat plan)? imageFor,
    // Handles Function for this part of the statistics page.
    String Function(_MealPlanStat plan)? detailLabelFor,
    String? Function(_MealPlanStat plan)? detailImageFor,
  }) {
    final groups = <String, _FoodGroup>{};
    for (final plan in plans) {
      final label = labelFor(plan).trim();
      if (label.isEmpty) continue;
      final group = groups.putIfAbsent(label, () => _FoodGroup(label: label));
      group.count += 1;
      group.recipeId ??= plan.recipeId;
      group.imageUrl ??= imageFor?.call(plan);
      final detailLabel = detailLabelFor?.call(plan).trim() ?? label;
      if (detailLabel.isNotEmpty) {
        group.detailCounts[detailLabel] =
            (group.detailCounts[detailLabel] ?? 0) + 1;
        group.detailImages[detailLabel] ??=
            detailImageFor?.call(plan) ?? imageFor?.call(plan);
        group.detailRecipeIds[detailLabel] ??= plan.recipeId;
      }
    }
    return groups;
  }

  // Handles _ingredientGroups for this part of the statistics page.
  Future<Map<String, _FoodGroup>> _ingredientGroups(
    List<_MealPlanStat> plans,
  ) async {
    final groups = <String, _FoodGroup>{};
    for (final plan in plans) {
      final ingredients = await firestore
          .collection('recipes')
          .doc(plan.recipeId)
          .collection('ingredients')
          .get();
      for (final doc in ingredients.docs) {
        final data = doc.data();
        final name = _stringValue(data['name']);
        if (name.isEmpty) continue;
        final group = groups.putIfAbsent(name, () => _FoodGroup(label: name));
        group.count += 1;
        group.imageUrl ??= _stringValue(data['image']);
        group.detailCounts[plan.recipeName] =
            (group.detailCounts[plan.recipeName] ?? 0) + 1;
        group.detailImages[plan.recipeName] ??= plan.imageUrl;
        group.detailRecipeIds[plan.recipeName] ??= plan.recipeId;
      }
    }
    return groups;
  }

  // Handles _categoryGroups for this part of the statistics page.
  Future<Map<String, _FoodGroup>> _categoryGroups(
    List<_MealPlanStat> plans,
  ) async {
    final groups = <String, _FoodGroup>{};
    final cache = <String, String>{};
    for (final plan in plans) {
      for (final categoryId in plan.categoryIds) {
        final name = await _resolveCategoryName(
          cacheKey: 'category:$categoryId',
          collectionPath: firestore
              .collection('app_config')
              .doc('recipe_categories')
              .collection('items')
              .doc(categoryId),
          fallback: categoryId,
          cache: cache,
        );
        final group = groups.putIfAbsent(name, () => _FoodGroup(label: name));
        group.count += 1;
        group.detailCounts[plan.recipeName] =
            (group.detailCounts[plan.recipeName] ?? 0) + 1;
        group.detailImages[plan.recipeName] ??= plan.imageUrl;
        group.detailRecipeIds[plan.recipeName] ??= plan.recipeId;
      }
      for (final customCategoryId in plan.customCategoryIds) {
        final name = await _resolveCategoryName(
          cacheKey: 'custom:$customCategoryId',
          collectionPath: firestore
              .collection('custom')
              .doc('custom_categories')
              .collection('items')
              .doc(customCategoryId),
          fallback: customCategoryId,
          cache: cache,
        );
        final group = groups.putIfAbsent(name, () => _FoodGroup(label: name));
        group.count += 1;
        group.detailCounts[plan.recipeName] =
            (group.detailCounts[plan.recipeName] ?? 0) + 1;
        group.detailImages[plan.recipeName] ??= plan.imageUrl;
        group.detailRecipeIds[plan.recipeName] ??= plan.recipeId;
      }
      if (plan.categoryIds.isEmpty && plan.customCategoryIds.isEmpty) {
        final group = groups.putIfAbsent(
          'Uncategorised',
          () => _FoodGroup(label: 'Uncategorised'),
        );
        group.count += 1;
        group.detailCounts[plan.recipeName] =
            (group.detailCounts[plan.recipeName] ?? 0) + 1;
        group.detailImages[plan.recipeName] ??= plan.imageUrl;
        group.detailRecipeIds[plan.recipeName] ??= plan.recipeId;
      }
    }
    return groups;
  }

  // Handles _barItemsFromGroups for this part of the statistics page.
  List<FoodAnalyticBarItem> _barItemsFromGroups({
    required Map<String, _FoodGroup> groups,
    required int total,
    required IconData Function(String label) iconFor,
    bool showTextFallback = false,
  }) {
    final colors = const [
      Color(0xFF21AEEA),
      Color(0xFF54C27A),
      Color(0xFFFFB300),
      Color(0xFFFF7A59),
      Color(0xFF8E7CF3),
    ];
    final sorted = groups.values.toList()
      ..sort((left, right) => right.count.compareTo(left.count));
    return List.generate(sorted.length, (index) {
      final group = sorted[index];
      return FoodAnalyticBarItem(
        recipeId: group.recipeId,
        label: group.label,
        value: group.count,
        percent: total <= 0 ? 0 : group.count / total,
        icon: showTextFallback ? Icons.abc : iconFor(group.label),
        color: colors[index % colors.length],
        imageUrl: group.imageUrl,
        details: _detailItemsFromGroup(group),
      );
    });
  }

  // Handles _detailItemsFromGroup for this part of the statistics page.
  List<FoodAnalyticDetailItem> _detailItemsFromGroup(_FoodGroup group) {
    final details = group.detailCounts.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    return details
        .map(
          (entry) => FoodAnalyticDetailItem(
            recipeId: group.detailRecipeIds[entry.key],
            name: entry.key,
            quantity: entry.value,
            icon: _iconForRecipe(entry.key),
            imageUrl: group.detailImages[entry.key],
          ),
        )
        .toList();
  }

  // Handles _getUserMealPlans for this part of the statistics page.
  Future<List<_MealPlanStat>> _getUserMealPlans(
    String uid,
    ({DateTime start, DateTime end}) range,
  ) async {
    // Reads meal_plans from Firestore for one user and one date range.
    // Each document is converted into a small statistics row for calculations.
    final snapshot = await firestore
        .collection('meal_plans')
        .where('uid', isEqualTo: uid)
        .get();
    final plans = <_MealPlanStat>[];
    for (final doc in snapshot.docs) {
      final plan = await _mealPlanStatFromDoc(doc);
      if (!plan.date.isBefore(range.start) && !plan.date.isAfter(range.end)) {
        plans.add(plan);
      }
    }
    return plans..sort((left, right) => left.date.compareTo(right.date));
  }

  // Handles _getAllMealPlans for this part of the statistics page.
  Future<List<_MealPlanStat>> _getAllMealPlans(
    ({DateTime start, DateTime end}) range,
  ) async {
    // Admin reports use this to read every meal plan in the database, then
    // filter by date before building the charts.
    final nonAdminUserIds = await _nonAdminUserIds();
    final snapshot = await firestore.collection('meal_plans').get();
    final plans = <_MealPlanStat>[];
    for (final doc in snapshot.docs) {
      final plan = await _mealPlanStatFromDoc(doc);
      if (plan.plannerUid.isNotEmpty &&
          !nonAdminUserIds.contains(plan.plannerUid)) {
        continue;
      }
      if (!plan.date.isBefore(range.start) && !plan.date.isAfter(range.end)) {
        plans.add(plan);
      }
    }
    return plans..sort((left, right) => left.date.compareTo(right.date));
  }

  // Handles _dailyPlanCounts for this part of the statistics page.
  List<AdminDailyStatistic> _dailyPlanCounts(
    List<_MealPlanStat> plans,
    ({DateTime start, DateTime end}) range,
  ) {
    return _daysInRange(range).map((day) {
      final value = plans.where((plan) => _startOfDay(plan.date) == day).length;
      return AdminDailyStatistic(date: day, value: value);
    }).toList();
  }

  // Handles _dailyPostCounts for this part of the statistics page.
  List<AdminDailyStatistic> _dailyPostCounts(
    List<_CommunityRecipeStat> recipes,
    ({DateTime start, DateTime end}) range,
  ) {
    return _daysInRange(range).map((day) {
      final value = recipes
          .where((recipe) => _startOfDay(recipe.publishedAt) == day)
          .length;
      return AdminDailyStatistic(date: day, value: value);
    }).toList();
  }

  // Handles _adminSectionFromGroups for this part of the statistics page.
  AdminAnalyticSection _adminSectionFromGroups({
    required String title,
    required String summaryTitle,
    required String summaryValue,
    required String highlightTitle,
    required Map<String, _FoodGroup> groups,
    required IconData Function(String label) iconFor,
    bool useInitialMarkers = false,
  }) {
    return _adminSectionFromCounts(
      title: title,
      summaryTitle: summaryTitle,
      summaryValue: summaryValue,
      highlightTitle: highlightTitle,
      counts: {
        for (final entry in groups.entries) entry.key: entry.value.count,
      },
      imageUrls: {
        for (final entry in groups.entries) entry.key: entry.value.imageUrl,
      },
      details: {
        for (final entry in groups.entries)
          entry.key: _detailsFromFoodGroup(entry.value),
      },
      markerTexts: useInitialMarkers
          ? {for (final entry in groups.entries) entry.key: entry.key}
          : const {},
      iconFor: iconFor,
    );
  }

  // Handles _adminSectionFromPostCategories for this part of the statistics page.
  Future<AdminAnalyticSection> _adminSectionFromPostCategories({
    required String title,
    required String summaryTitle,
    required String highlightTitle,
    required List<_CommunityRecipeStat> recipes,
  }) async {
    final categories = await _buildPostRatingCategories(recipes);
    return _adminSectionFromCounts(
      title: title,
      summaryTitle: summaryTitle,
      summaryValue: categories.length.toString(),
      highlightTitle: highlightTitle,
      counts: {
        for (final category in categories)
          category.name: category.ratedDishCount,
      },
      markerTexts: {
        for (final category in categories) category.name: category.name,
      },
      iconFor: _iconForCategory,
    );
  }

  // Handles _adminSectionFromCounts for this part of the statistics page.
  AdminAnalyticSection _adminSectionFromCounts({
    required String title,
    required String summaryTitle,
    required String summaryValue,
    required String highlightTitle,
    required Map<String, int> counts,
    required IconData Function(String label) iconFor,
    Map<String, List<AdminRankedStatisticDetail>> details = const {},
    Map<String, String?> imageUrls = const {},
    Map<String, String> markerTexts = const {},
    // Handles Function for this part of the statistics page.
    Color Function(String label)? colorFor,
    bool includeZeroValues = false,
    bool preserveOrder = false,
  }) {
    final items = _rankedStatsFromCounts(
      counts: counts,
      total: counts.values.fold<int>(0, (total, value) => total + value),
      iconFor: iconFor,
      details: details,
      imageUrls: imageUrls,
      markerTexts: markerTexts,
      colorFor: colorFor,
      includeZeroValues: includeZeroValues,
      preserveOrder: preserveOrder,
    );
    return AdminAnalyticSection(
      title: title,
      summaryTitle: summaryTitle,
      summaryValue: summaryValue,
      highlightTitle: highlightTitle,
      highlightValue: items.isEmpty ? '-' : items.first.label,
      items: items,
    );
  }

  // Handles _rankedStatsFromCounts for this part of the statistics page.
  List<AdminRankedStatistic> _rankedStatsFromCounts({
    required Map<String, int> counts,
    required int total,
    required IconData Function(String label) iconFor,
    Map<String, List<AdminRankedStatisticDetail>> details = const {},
    Map<String, String?> imageUrls = const {},
    Map<String, String> markerTexts = const {},
    // Handles Function for this part of the statistics page.
    Color Function(String label)? colorFor,
    bool includeZeroValues = false,
    bool preserveOrder = false,
    List<Color> colors = const [
      Color(0xFF21AEEA),
      Color(0xFF54C27A),
      Color(0xFFFFB300),
      Color(0xFFFF7A59),
      Color(0xFF8E7CF3),
    ],
  }) {
    final entries = counts.entries
        .where((entry) => includeZeroValues || entry.value > 0)
        .toList();
    if (!preserveOrder) {
      entries.sort((left, right) => right.value.compareTo(left.value));
    }
    final denominator = total <= 0 ? 1 : total;
    return List.generate(entries.length, (index) {
      final entry = entries[index];
      return AdminRankedStatistic(
        label: entry.key,
        value: entry.value,
        percent: entry.value / denominator,
        icon: iconFor(entry.key),
        color: colorFor?.call(entry.key) ?? colors[index % colors.length],
        imageUrl: imageUrls[entry.key],
        markerText: markerTexts[entry.key],
        details: details[entry.key] ?? const [],
      );
    });
  }

  // Handles _buildAdminRecipePerformance for this part of the statistics page.
  Future<RecipePerformanceStatistics> _buildAdminRecipePerformance(
    List<_CommunityRecipeStat> recipes,
  ) async {
    final items = <RecipePerformanceItem>[];
    for (final recipe in recipes) {
      final favouriteCount = await _recipeFavouriteCount(recipe.id);
      items.add(
        RecipePerformanceItem(
          id: recipe.id,
          name: recipe.name,
          imageUrl: recipe.imageUrl,
          totalViews: recipe.totalViews,
          commentCount: recipe.commentCount,
          favouriteCount: favouriteCount,
          ratingCount: recipe.ratingCount,
          publishedAt: recipe.publishedAt,
        ),
      );
    }

    return RecipePerformanceStatistics(
      dateRange: 'Not available',
      totalViews: recipes.fold<int>(
        0,
        (total, recipe) => total + recipe.totalViews,
      ),
      totalComments: recipes.fold<int>(
        0,
        (total, recipe) => total + recipe.commentCount,
      ),
      totalFavourites: items.fold<int>(
        0,
        (total, recipe) => total + recipe.favouriteCount,
      ),
      totalRatings: recipes.fold<int>(
        0,
        (total, recipe) => total + recipe.ratingCount,
      ),
      recipes: items
        ..sort((left, right) => right.totalViews.compareTo(left.totalViews)),
    );
  }

  // Handles _detailsFromFoodGroup for this part of the statistics page.
  List<AdminRankedStatisticDetail> _detailsFromFoodGroup(_FoodGroup group) {
    final entries = group.detailCounts.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    return entries
        .map(
          (entry) => AdminRankedStatisticDetail(
            title: entry.key,
            quantity: entry.value,
            icon: _iconForRecipe(entry.key),
            imageUrl: group.detailImages[entry.key],
          ),
        )
        .toList();
  }

  // Handles _detailsByMealTime for this part of the statistics page.
  Map<String, List<AdminRankedStatisticDetail>> _detailsByMealTime(
    Map<String, List<_MealPlanStat>> groups,
  ) {
    return {
      for (final entry in groups.entries)
        entry.key: _detailsFromMealPlans(entry.value),
    };
  }

  // Handles _detailsByMethod for this part of the statistics page.
  Map<String, List<AdminRankedStatisticDetail>> _detailsByMethod(
    List<_MealPlanStat> plans,
  ) {
    final groups = <String, List<_MealPlanStat>>{
      'Explore Community': <_MealPlanStat>[],
      'From Library': <_MealPlanStat>[],
      'Generate With AI': <_MealPlanStat>[],
    };
    for (final plan in plans) {
      groups.putIfAbsent(_methodLabel(plan.source), () => []).add(plan);
    }
    return {
      for (final entry in groups.entries)
        entry.key: _detailsFromMealPlans(entry.value, includeMealTime: true),
    };
  }

  // Handles _detailsByMealDifficulty for this part of the statistics page.
  Map<String, List<AdminRankedStatisticDetail>> _detailsByMealDifficulty(
    List<_MealPlanStat> plans,
  ) {
    return {
      for (var level = 1; level <= 5; level++)
        '$level Star': _detailsFromMealPlans(
          plans.where((plan) => plan.difficultyLevel == level).toList(),
        ),
    };
  }

  // Handles _detailsByPostDifficulty for this part of the statistics page.
  Map<String, List<AdminRankedStatisticDetail>> _detailsByPostDifficulty(
    List<_CommunityRecipeStat> recipes,
  ) {
    return {
      for (var level = 1; level <= 5; level++)
        '$level Star': recipes
            .where((recipe) => recipe.difficultyLevel == level)
            .map(
              (recipe) => AdminRankedStatisticDetail(
                title: recipe.name,
                subtitle: DateFormat('MMM d, yyyy').format(recipe.publishedAt),
                quantity: 1,
                icon: _iconForRecipe(recipe.name),
                imageUrl: recipe.imageUrl,
              ),
            )
            .toList(),
    };
  }

  // Handles _detailsByRecipes for this part of the statistics page.
  Map<String, List<AdminRankedStatisticDetail>> _detailsByRecipes(
    List<_CommunityRecipeStat> recipes,
  ) {
    return {
      for (final recipe in recipes)
        recipe.name: [
          AdminRankedStatisticDetail(
            title: recipe.name,
            subtitle: DateFormat('MMM d, yyyy').format(recipe.publishedAt),
            quantity: 1,
            icon: _iconForRecipe(recipe.name),
            imageUrl: recipe.imageUrl,
          ),
        ],
    };
  }

  // Handles _detailsByRecipeName for this part of the statistics page.
  Map<String, List<AdminRankedStatisticDetail>> _detailsByRecipeName(
    List<_MealPlanStat> plans,
  ) {
    final groups = <String, List<_MealPlanStat>>{};
    for (final plan in plans) {
      groups.putIfAbsent(plan.recipeName, () => []).add(plan);
    }
    return {
      for (final entry in groups.entries)
        entry.key: _detailsFromMealPlans(entry.value),
    };
  }

  // Handles _detailsFromMealPlans for this part of the statistics page.
  List<AdminRankedStatisticDetail> _detailsFromMealPlans(
    List<_MealPlanStat> plans, {
    bool includeMealTime = false,
  }) {
    final groups = <String, List<_MealPlanStat>>{};
    for (final plan in plans) {
      groups.putIfAbsent(plan.recipeId, () => []).add(plan);
    }
    return groups.values.map((sameRecipePlans) {
      final plan = sameRecipePlans.first;
      final date = DateFormat('MMM d, yyyy').format(plan.date);
      return AdminRankedStatisticDetail(
        title: plan.recipeName,
        subtitle: includeMealTime ? '$date - ${plan.mealCategoryName}' : date,
        quantity: sameRecipePlans.length,
        icon: _iconForRecipe(plan.recipeName),
        imageUrl: plan.imageUrl,
      );
    }).toList()..sort((left, right) => right.quantity.compareTo(left.quantity));
  }

  // Handles _mealPlanStatFromDoc for this part of the statistics page.
  Future<_MealPlanStat> _mealPlanStatFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final recipeId = _stringValue(
      data['recipeId'] ?? data['recipe_id'] ?? data['recipeID'],
      fallback: doc.id,
    );
    final recipeDoc = await firestore.collection('recipes').doc(recipeId).get();
    final recipeData = recipeDoc.data() ?? const <String, dynamic>{};
    final recipeName = _stringValue(
      recipeData['name'],
      fallback: _stringValue(data['recipeName'], fallback: 'Untitled Recipe'),
    );
    final planImage = _stringValue(data['recipeImage']);
    final recipeImage = _firstMediaUrl(recipeData['media']);
    return _MealPlanStat(
      id: doc.id,
      plannerUid: _stringValue(
        data['uid'] ?? data['userId'] ?? data['user_id'] ?? data['creatorUid'],
      ),
      recipeId: recipeId,
      recipeName: recipeName,
      imageUrl: planImage.isNotEmpty ? planImage : recipeImage,
      date: _dateTime(
        data['date'] ??
            data['plannedDate'] ??
            data['selectedDate'] ??
            data['createdAt'] ??
            data['updatedAt'],
      ),
      source: _stringValue(
        data['source'],
        fallback: _stringValue(data['creationMethod']),
      ),
      mealCategoryId: _stringValue(data['mealCategoryId']),
      mealCategoryName: _stringValue(
        data['mealCategoryName'],
        fallback: 'Meal',
      ),
      cookingTimeMinutes: _durationMinutes(
        data['cookingTime'] ??
            data['preparationTime'] ??
            recipeData['preparationTime'] ??
            data['durationLabel'],
      ),
      difficultyLevel: _difficultyLevel(
        recipeData['difficultyLevel'] ?? data['difficultyLabel'],
      ),
      categoryIds: _stringList(recipeData['categoryIds']),
      customCategoryIds: _stringList(recipeData['customCategoryIds']),
    );
  }

  // Handles _getUserPlannedRecipeNutrition for this part of the statistics page.
  Future<List<_RecipeNutritionStat>> _getUserPlannedRecipeNutrition(
    String uid,
    ({DateTime start, DateTime end}) range,
  ) async {
    // Gets the user's planned recipes first, then opens each recipe document
    // to collect nutrition data for calories, protein, carbs, and fat.
    final plans = await _getUserMealPlans(uid, range);
    final items = <_RecipeNutritionStat>[];
    for (final plan in plans) {
      final recipeRef = firestore.collection('recipes').doc(plan.recipeId);
      items.add(
        _RecipeNutritionStat(
          id: plan.recipeId,
          name: plan.recipeName,
          imageUrl: plan.imageUrl,
          date: plan.date,
          nutrition: await _recipeNutrition(recipeRef),
        ),
      );
    }
    return items..sort((left, right) => left.date.compareTo(right.date));
  }

  // Handles _getAllPlannedRecipeNutrition for this part of the statistics page.
  Future<List<_RecipeNutritionStat>> _getAllPlannedRecipeNutrition(
    ({DateTime start, DateTime end}) range,
  ) async {
    // Admin nutrient insight uses this to collect nutrition from all planned
    // recipes in the selected date range.
    final plans = await _getAllMealPlans(range);
    final items = <_RecipeNutritionStat>[];
    for (final plan in plans) {
      final recipeRef = firestore.collection('recipes').doc(plan.recipeId);
      items.add(
        _RecipeNutritionStat(
          id: plan.recipeId,
          name: plan.recipeName,
          imageUrl: plan.imageUrl,
          date: plan.date,
          nutrition: await _recipeNutrition(recipeRef),
        ),
      );
    }
    return items..sort((left, right) => left.date.compareTo(right.date));
  }

  // Handles _getUserPostedRecipeNutrition for this part of the statistics page.
  Future<List<_RecipeNutritionStat>> _getUserPostedRecipeNutrition(
    String uid,
    ({DateTime start, DateTime end}) range,
  ) async {
    final recipes = await _getUserSharedRecipes(uid);
    final items = <_RecipeNutritionStat>[];

    for (final recipe in recipes) {
      if (recipe.publishedAt.isBefore(range.start) ||
          recipe.publishedAt.isAfter(range.end)) {
        continue;
      }
      final recipeRef = firestore.collection('recipes').doc(recipe.id);
      items.add(
        _RecipeNutritionStat(
          id: recipe.id,
          name: recipe.name,
          imageUrl: recipe.imageUrl,
          date: recipe.publishedAt,
          nutrition: await _recipeNutrition(recipeRef),
        ),
      );
    }

    return items..sort((left, right) => left.date.compareTo(right.date));
  }

  // Handles _recipeNutrition for this part of the statistics page.
  Future<_RecipeNutrition> _recipeNutrition(
    DocumentReference<Map<String, dynamic>> recipeRef,
  ) async {
    try {
      final ingredients = await recipeRef.collection('ingredients').get();
      var calories = 0.0;
      var carbohydrate = 0.0;
      var protein = 0.0;
      var fat = 0.0;

      for (final ingredient in ingredients.docs) {
        final nutrients = ingredient.data()['nutrients'];
        if (nutrients is! Map) continue;
        calories += _nutrientValue(nutrients, const ['calories', 'energy']);
        carbohydrate += _nutrientValue(nutrients, const [
          'carbohydrates',
          'carbohydrate',
          'totalCarbohydrate',
          'carbohydrateByDifference',
        ]);
        protein += _nutrientValue(nutrients, const ['protein', 'proteins']);
        fat += _nutrientValue(nutrients, const [
          'fat',
          'fats',
          'totalFat',
          'totalLipid',
        ]);
      }

      return _RecipeNutrition(
        caloriesKcal: calories.round(),
        carbohydrateGram: carbohydrate.round(),
        proteinGram: protein.round(),
        fatGram: fat.round(),
      );
    } on FirebaseException {
      return const _RecipeNutrition.zero();
    }
  }

  // Handles _nutrientValue for this part of the statistics page.
  double _nutrientValue(Map<dynamic, dynamic> nutrients, List<String> keys) {
    for (final key in keys) {
      final value = _valueForInsensitiveKey(nutrients, key);
      final parsed = _numberFromNutrient(value);
      if (parsed != null) return parsed;
    }
    return 0;
  }

  Object? _valueForInsensitiveKey(Map<dynamic, dynamic> map, String key) {
    final target = key.toLowerCase();
    for (final entry in map.entries) {
      final entryKey = entry.key.toString().toLowerCase();
      if (entryKey == target) return entry.value;
    }
    return null;
  }

  // Handles _numberFromNutrient for this part of the statistics page.
  double? _numberFromNutrient(Object? value) {
    if (value is num) return value.toDouble();
    if (value is Map) {
      for (final key in const ['value', 'amount']) {
        final parsed = _numberFromNutrient(value[key]);
        if (parsed != null) return parsed;
      }
    }
    return double.tryParse(value?.toString() ?? '');
  }

  // Handles _buildCaloriesIntakeStatistics for this part of the statistics page.
  CaloriesIntakeStatistics _buildCaloriesIntakeStatistics({
    required List<_RecipeNutritionStat> recipes,
    required ({DateTime start, DateTime end}) range,
  }) {
    final grouped = _groupNutritionByDay(recipes);
    final days = _daysInRange(range).map((date) {
      final items = grouped[date] ?? const <_RecipeNutritionStat>[];
      final meals = items
          .map(
            (item) => CaloriesMealItem(
              name: item.name,
              caloriesKcal: item.nutrition.caloriesKcal,
              carbohydrateGram: item.nutrition.carbohydrateGram,
              proteinGram: item.nutrition.proteinGram,
              fatGram: item.nutrition.fatGram,
              icon: _iconForRecipe(item.name),
              imageUrl: item.imageUrl,
            ),
          )
          .toList();
      return CaloriesDailyIntake(
        date: date,
        weekdayLabel: DateFormat('EEE').format(date),
        totalPlannedMeal: meals.length,
        totalCaloriesKcal: _sumNutrition(items, (item) => item.caloriesKcal),
        totalCarbohydrateGram: _sumNutrition(
          items,
          (item) => item.carbohydrateGram,
        ),
        totalProteinGram: _sumNutrition(items, (item) => item.proteinGram),
        totalFatGram: _sumNutrition(items, (item) => item.fatGram),
        meals: meals,
      );
    }).toList();

    return CaloriesIntakeStatistics(
      dateRange: _formatRange(range.start, range.end),
      totalMeal: recipes.length,
      averageCaloriesKcal: _averageNutrition(
        recipes,
        (item) => item.caloriesKcal,
      ),
      dailyIntakes: days,
    );
  }

  // Handles _buildCaloriesPostedStatistics for this part of the statistics page.
  CaloriesPostedStatistics _buildCaloriesPostedStatistics({
    required List<_RecipeNutritionStat> recipes,
    required ({DateTime start, DateTime end}) range,
  }) {
    final grouped = _groupNutritionByDay(recipes);
    final days = _daysInRange(range).map((date) {
      final items = grouped[date] ?? const <_RecipeNutritionStat>[];
      final posts = items
          .map(
            (item) => CaloriesPostedItem(
              recipeName: item.name,
              caloriesKcal: item.nutrition.caloriesKcal,
              carbohydrateGram: item.nutrition.carbohydrateGram,
              proteinGram: item.nutrition.proteinGram,
              fatGram: item.nutrition.fatGram,
              icon: _iconForRecipe(item.name),
              imageUrl: item.imageUrl,
            ),
          )
          .toList();
      return CaloriesPostedDay(
        date: date,
        weekdayLabel: DateFormat('EEE').format(date),
        totalPost: posts.length,
        totalCaloriesKcal: _sumNutrition(items, (item) => item.caloriesKcal),
        totalCarbohydrateGram: _sumNutrition(
          items,
          (item) => item.carbohydrateGram,
        ),
        totalProteinGram: _sumNutrition(items, (item) => item.proteinGram),
        totalFatGram: _sumNutrition(items, (item) => item.fatGram),
        posts: posts,
      );
    }).toList();

    return CaloriesPostedStatistics(
      dateRange: _formatRange(range.start, range.end),
      totalPost: recipes.length,
      averageCaloriesKcal: _averageNutrition(
        recipes,
        (item) => item.caloriesKcal,
      ),
      averageCarbohydrateGram: _averageNutrition(
        recipes,
        (item) => item.carbohydrateGram,
      ),
      averageProteinGram: _averageNutrition(
        recipes,
        (item) => item.proteinGram,
      ),
      averageFatGram: _averageNutrition(recipes, (item) => item.fatGram),
      dailyPosts: days,
    );
  }

  // Handles _groupNutritionByDay for this part of the statistics page.
  Map<DateTime, List<_RecipeNutritionStat>> _groupNutritionByDay(
    List<_RecipeNutritionStat> recipes,
  ) {
    final grouped = <DateTime, List<_RecipeNutritionStat>>{};
    for (final recipe in recipes) {
      final day = DateTime(
        recipe.date.year,
        recipe.date.month,
        recipe.date.day,
      );
      grouped.putIfAbsent(day, () => <_RecipeNutritionStat>[]).add(recipe);
    }
    return Map.fromEntries(
      grouped.entries.toList()
        ..sort((left, right) => left.key.compareTo(right.key)),
    );
  }

  // Handles _daysInRange for this part of the statistics page.
  List<DateTime> _daysInRange(({DateTime start, DateTime end}) range) {
    final days = <DateTime>[];
    var cursor = _startOfDay(range.start);
    final end = _startOfDay(range.end);
    while (!cursor.isAfter(end)) {
      days.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return days;
  }

  // Handles _emptyMostCookedDays for this part of the statistics page.
  List<MostCookedRecipeDay> _emptyMostCookedDays(
    ({DateTime start, DateTime end}) range,
  ) {
    return _daysInRange(range)
        .map(
          (day) => MostCookedRecipeDay(
            date: day,
            totalQuantity: 0,
            recipes: const [],
          ),
        )
        .toList();
  }

  // Handles _currentUserCreatedAt for this part of the statistics page.
  Future<DateTime> _currentUserCreatedAt(String uid) async {
    try {
      final userDoc = await firestore.collection('users').doc(uid).get();
      final createdAt = _dateTime(userDoc.data()?['createdAt']);
      if (createdAt.millisecondsSinceEpoch > 0) return createdAt;
    } on FirebaseException {
      // Fall back to FirebaseAuth metadata when the user document is missing.
    }
    return auth.currentUser?.metadata.creationTime ?? DateTime.now();
  }

  // Handles _nonAdminUserIds for this part of the statistics page.
  Future<Set<String>> _nonAdminUserIds() async {
    final snapshot = await firestore.collection('users').get();
    return snapshot.docs
        .where((doc) => !_isAdminUser(doc.data()))
        .map((doc) => doc.id)
        .toSet();
  }

  // Handles _isAdminUser for this part of the statistics page.
  bool _isAdminUser(Map<String, dynamic> data) {
    return _stringValue(data['role']).toLowerCase() == 'admin';
  }

  // Handles _buildSelfSlides for this part of the statistics page.
  List<StatisticsHeroSlide> _buildSelfSlides(
    List<_MealPlanStat> plans, {
    required DateTime createdAt,
  }) {
    final now = DateTime.now();
    final today = _startOfDay(now);
    final accountCreatedDay = _startOfDay(createdAt);
    final planDays = plans.map((plan) => _startOfDay(plan.date)).toSet();
    final totalMealPlanned = plans.length;
    final dayCreated = today.isBefore(accountCreatedDay)
        ? 0
        : today.difference(accountCreatedDay).inDays + 1;
    final plannedDays = planDays.length;
    final unplannedDays = dayCreated <= 0
        ? 0
        : (dayCreated - plannedDays).clamp(0, dayCreated);
    final currentStreak = _currentPlanStreak(planDays, today);
    final totalDish = plans.map((plan) => plan.recipeId).toSet().length;
    final totalCategory = <String>{
      for (final plan in plans) ...plan.categoryIds,
      for (final plan in plans) ...plan.customCategoryIds,
    }.length;
    final averageDifficulty = plans.isEmpty
        ? 0.0
        : plans.fold<int>(0, (total, plan) => total + plan.difficultyLevel) /
              plans.length;
    final totalCookingMinutes = plans.fold<int>(
      0,
      (total, plan) => total + plan.cookingTimeMinutes,
    );
    final plannedPercent = dayCreated <= 0 ? 0.0 : plannedDays / dayCreated;
    final unplannedPercent = dayCreated <= 0 ? 0.0 : unplannedDays / dayCreated;

    return [
      StatisticsHeroSlide(
        title: 'Dailies',
        type: StatisticsHeroSlideType.overview,
        metrics: [
          StatisticsMetric(
            label: 'Planned Meal',
            value: totalMealPlanned.toString(),
            tone: StatisticsMetricTone.positive,
          ),
          StatisticsMetric(
            label: 'Day Created',
            value: dayCreated.toString(),
            tone: StatisticsMetricTone.negative,
          ),
          StatisticsMetric(
            label: 'Planned Meal Streak',
            value: currentStreak.toString(),
            suffix: 'Days',
            tone: StatisticsMetricTone.neutral,
          ),
          StatisticsMetric(
            label: 'Unplanned Meals',
            value: unplannedDays.toString(),
            suffix: 'Days',
            tone: StatisticsMetricTone.neutral,
          ),
        ],
      ),
      StatisticsHeroSlide(
        title: 'Days Using This App',
        type: StatisticsHeroSlideType.appUsage,
        metrics: [
          StatisticsMetric(label: 'Days', value: dayCreated.toString()),
          StatisticsMetric(
            label: 'Day with Planned Meals',
            value: plannedDays.toString(),
            tone: StatisticsMetricTone.positive,
          ),
          StatisticsMetric(
            label: 'Unplanned Meals',
            value: unplannedDays.toString(),
            tone: StatisticsMetricTone.negative,
          ),
        ],
        progress: StatisticsProgress(
          positivePercent: plannedPercent,
          negativePercent: unplannedPercent,
        ),
      ),
      StatisticsHeroSlide(
        title: 'Achievement',
        type: StatisticsHeroSlideType.achievement,
        metrics: [
          StatisticsMetric(label: 'Total Dish', value: totalDish.toString()),
          StatisticsMetric(
            label: 'Different Category',
            value: totalCategory.toString(),
          ),
          StatisticsMetric(
            label: 'Difficulty Dishes',
            value: averageDifficulty.toStringAsFixed(1),
          ),
          StatisticsMetric(
            label: 'Cooking Time',
            value: _formatHours(totalCookingMinutes),
            isWide: true,
          ),
        ],
      ),
    ];
  }

  // Handles _currentPlanStreak for this part of the statistics page.
  int _currentPlanStreak(Set<DateTime> planDays, DateTime today) {
    if (planDays.isEmpty) return 0;
    var cursor = today;
    var streak = 0;
    while (planDays.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // Handles _formatHours for this part of the statistics page.
  String _formatHours(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours <= 0) return '$remainingMinutes Min';
    if (remainingMinutes <= 0) return '$hours Hrs';
    return '$hours Hrs $remainingMinutes Min';
  }

  // Handles _getMealCategoryConfigs for this part of the statistics page.
  Future<List<_MealCategoryConfig>> _getMealCategoryConfigs() async {
    try {
      final snapshot = await firestore
          .collection('app_config')
          .doc('meal_categories')
          .collection('items')
          .get();
      final categories = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return _MealCategoryConfig(
              id: doc.id,
              name: _mealTimeLabel(
                _stringValue(data['name'], fallback: doc.id),
              ),
            );
          })
          .where((category) => category.name.isNotEmpty)
          .toList();
      if (categories.isNotEmpty) return categories;
    } on FirebaseException {
      // Fall back to the standard meal times when config is unavailable.
    }
    return const [
      _MealCategoryConfig(id: 'breakfast', name: 'Breakfast'),
      _MealCategoryConfig(id: 'lunch', name: 'Lunch'),
      _MealCategoryConfig(id: 'dinner', name: 'Dinner'),
      _MealCategoryConfig(id: 'snack', name: 'Snack'),
    ];
  }

  // Handles _sumNutrition for this part of the statistics page.
  int _sumNutrition(
    List<_RecipeNutritionStat> recipes,
    int Function(_RecipeNutrition nutrition) value,
  ) {
    return recipes.fold<int>(0, (total, item) => total + value(item.nutrition));
  }

  // Handles _averageNutrition for this part of the statistics page.
  int _averageNutrition(
    List<_RecipeNutritionStat> recipes,
    int Function(_RecipeNutrition nutrition) value,
  ) {
    if (recipes.isEmpty) return 0;
    final total = _sumNutrition(recipes, value);
    return (total / recipes.length).round();
  }

  // Handles _getUserSharedRecipes for this part of the statistics page.
  Future<List<_CommunityRecipeStat>> _getUserSharedRecipes(String uid) async {
    // Loads recipes owned by the user, then keeps only recipes that are shared
    // publicly and finalized.
    final recipes = await _getUserOwnedRecipes(uid);
    return recipes.where((recipe) => recipe.isShared).toList();
  }

  // Handles _getAllSharedRecipes for this part of the statistics page.
  Future<List<_CommunityRecipeStat>> _getAllSharedRecipes(
    ({DateTime start, DateTime end}) range,
  ) async {
    // Loads all recipe documents from Firestore, then keeps public finalized
    // posts that fall inside the requested date range.
    final nonAdminUserIds = await _nonAdminUserIds();
    final snapshot = await firestore.collection('recipes').get();
    final recipes = snapshot.docs
        .map((doc) => _CommunityRecipeStat.fromFirestore(doc.id, doc.data()))
        .where(
          (recipe) =>
              recipe.isShared &&
              (recipe.creatorUid.isEmpty ||
                  nonAdminUserIds.contains(recipe.creatorUid)) &&
              !recipe.publishedAt.isBefore(range.start) &&
              !recipe.publishedAt.isAfter(range.end),
        )
        .toList();
    return recipes
      ..sort((left, right) => left.publishedAt.compareTo(right.publishedAt));
  }

  // Handles _getUserOwnedRecipes for this part of the statistics page.
  Future<List<_CommunityRecipeStat>> _getUserOwnedRecipes(String uid) async {
    // Checks the recipes collection for records that belong to this user.
    // The code supports a few possible creator id fields used by older data.
    final docsById = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

    final creatorIdSnapshot = await firestore
        .collection('recipes')
        .where('creatorId', isEqualTo: uid)
        .get();
    for (final doc in creatorIdSnapshot.docs) {
      docsById[doc.id] = doc;
    }

    final creatorUidSnapshot = await firestore
        .collection('recipes')
        .where('creatorUid', isEqualTo: uid)
        .get();
    for (final doc in creatorUidSnapshot.docs) {
      docsById[doc.id] = doc;
    }

    return docsById.values
        .map((doc) => _CommunityRecipeStat.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  // Handles _allRecipeCategoryNames for this part of the statistics page.
  Future<Set<String>> _allRecipeCategoryNames(
    List<_CommunityRecipeStat> recipes,
  ) async {
    final cache = <String, String>{};
    final names = <String>{};
    for (final recipe in recipes) {
      names.addAll(await _categoryNamesForRecipe(recipe, cache: cache));
    }
    return names;
  }

  // Handles _topMealName for this part of the statistics page.
  String _topMealName(List<_MealPlanStat> plans) {
    if (plans.isEmpty) return '-';
    final counts = <String, int>{};
    for (final plan in plans) {
      counts[plan.recipeName] = (counts[plan.recipeName] ?? 0) + 1;
    }
    final entries = counts.entries.toList()
      ..sort((left, right) => right.value.compareTo(left.value));
    return entries.first.key;
  }

  // Handles _topFoodGroupName for this part of the statistics page.
  String _topFoodGroupName(Map<String, _FoodGroup> groups) {
    if (groups.isEmpty) return '-';
    final entries = groups.entries.toList()
      ..sort((left, right) => right.value.count.compareTo(left.value.count));
    return entries.first.key;
  }

  // Handles _averageDifficulty for this part of the statistics page.
  double _averageDifficulty(List<_MealPlanStat> plans) {
    if (plans.isEmpty) return 0;
    return plans.fold<int>(0, (total, plan) => total + plan.difficultyLevel) /
        plans.length;
  }

  // Handles _averagePostDifficulty for this part of the statistics page.
  double _averagePostDifficulty(List<_CommunityRecipeStat> recipes) {
    if (recipes.isEmpty) return 0;
    return recipes.fold<int>(
          0,
          (total, recipe) => total + recipe.difficultyLevel,
        ) /
        recipes.length;
  }

  // Handles _buildPostRatingCategories for this part of the statistics page.
  Future<List<PostRatingCategory>> _buildPostRatingCategories(
    List<_CommunityRecipeStat> recipes,
  ) async {
    final groups = <String, List<_CommunityRecipeStat>>{};
    final categoryNameCache = <String, String>{};

    for (final recipe in recipes) {
      final categories = await _categoryNamesForRecipe(
        recipe,
        cache: categoryNameCache,
      );
      for (final category in categories) {
        groups.putIfAbsent(category, () => []).add(recipe);
      }
    }

    final categoryItems =
        groups.entries.map((entry) {
          final dishes = entry.value
              .map(
                (recipe) => PostRatingItem(
                  id: recipe.id,
                  name: recipe.name,
                  rating: recipe.averageRating,
                  ratingCount: recipe.ratingCount,
                  icon: _iconForRecipe(recipe.name),
                  imageUrl: recipe.imageUrl,
                ),
              )
              .toList();
          final totalRatings = entry.value.fold<int>(
            0,
            (total, recipe) => total + recipe.ratingCount,
          );
          final ratingTotal = entry.value.fold<double>(
            0,
            (total, recipe) =>
                total + (recipe.averageRating * recipe.ratingCount),
          );
          final averageRating = totalRatings == 0
              ? 0.0
              : ratingTotal / totalRatings;

          return PostRatingCategory(
            name: entry.key,
            averageRating: averageRating,
            ratedDishCount: totalRatings,
            icon: _iconForCategory(entry.key),
            dishes: dishes,
          );
        }).toList()..sort(
          (left, right) => right.averageRating.compareTo(left.averageRating),
        );

    return categoryItems;
  }

  // Handles _categoryNamesForRecipe for this part of the statistics page.
  Future<List<String>> _categoryNamesForRecipe(
    _CommunityRecipeStat recipe, {
    required Map<String, String> cache,
  }) async {
    final names = <String>[];
    for (final categoryId in recipe.categoryIds) {
      names.add(
        await _resolveCategoryName(
          cacheKey: 'category:$categoryId',
          collectionPath: firestore
              .collection('app_config')
              .doc('recipe_categories')
              .collection('items')
              .doc(categoryId),
          fallback: categoryId,
          cache: cache,
        ),
      );
    }
    for (final customCategoryId in recipe.customCategoryIds) {
      names.add(
        await _resolveCategoryName(
          cacheKey: 'custom:$customCategoryId',
          collectionPath: firestore
              .collection('custom')
              .doc('custom_categories')
              .collection('items')
              .doc(customCategoryId),
          fallback: customCategoryId,
          cache: cache,
        ),
      );
    }

    return names.isEmpty ? const ['Uncategorised'] : names;
  }

  // Handles _resolveCategoryName for this part of the statistics page.
  Future<String> _resolveCategoryName({
    required String cacheKey,
    required DocumentReference<Map<String, dynamic>> collectionPath,
    required String fallback,
    required Map<String, String> cache,
  }) async {
    final cached = cache[cacheKey];
    if (cached != null) return cached;

    final doc = await collectionPath.get();
    final name = _stringValue(doc.data()?['name'], fallback: fallback);
    cache[cacheKey] = name;
    return name;
  }

  // Handles getUserCaloriesIntake for this part of the statistics page.
  Future<CaloriesIntakeStatistics> getUserCaloriesIntake({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final range = _resolveRange(startDate, endDate);
    final uid = auth.currentUser?.uid ?? '';
    final plannedRecipes = uid.isEmpty
        ? <_RecipeNutritionStat>[]
        : await _getUserPlannedRecipeNutrition(uid, range);

    return _buildCaloriesIntakeStatistics(
      recipes: plannedRecipes,
      range: range,
    );
  }

  // Handles getUserCaloriesPosted for this part of the statistics page.
  Future<CaloriesPostedStatistics> getUserCaloriesPosted({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final range = _resolveRange(startDate, endDate);
    final uid = auth.currentUser?.uid ?? '';
    final recipes = uid.isEmpty
        ? <_RecipeNutritionStat>[]
        : await _getUserPostedRecipeNutrition(uid, range);

    return _buildCaloriesPostedStatistics(recipes: recipes, range: range);
  }

  // Handles _buildCommunitySlides for this part of the statistics page.
  List<StatisticsHeroSlide> _buildCommunitySlides(
    List<_CommunityRecipeStat> recipes,
  ) {
    final totalPost = recipes.length;
    final totalRatings = recipes.fold<int>(
      0,
      (total, recipe) => total + recipe.ratingCount,
    );
    final averageRating = _averagePostedRecipeRating(recipes);
    final totalComments = recipes.fold<int>(
      0,
      (total, recipe) => total + recipe.commentCount,
    );
    final totalViews = recipes.fold<int>(
      0,
      (total, recipe) => total + recipe.totalViews,
    );
    final topRatedRecipe = _topRatedRecipe(recipes);
    final mostRatedRecipe = _mostRatedRecipe(recipes);

    return [
      StatisticsHeroSlide(
        title: 'Community Posts',
        type: StatisticsHeroSlideType.overview,
        metrics: [
          StatisticsMetric(
            label: 'Total Post',
            value: totalPost.toString(),
            tone: StatisticsMetricTone.positive,
          ),
          StatisticsMetric(
            label: 'Total Rating',
            value: totalRatings.toString(),
            tone: StatisticsMetricTone.positive,
          ),
          StatisticsMetric(
            label: 'Average Rating',
            value: averageRating.toStringAsFixed(1),
            tone: StatisticsMetricTone.positive,
          ),
          StatisticsMetric(
            label: 'Comments',
            value: totalComments.toString(),
            tone: StatisticsMetricTone.positive,
          ),
        ],
      ),
      StatisticsHeroSlide(
        title: 'Community Engagement',
        type: StatisticsHeroSlideType.overview,
        metrics: [
          StatisticsMetric(
            label: 'Total Views',
            value: totalViews.toString(),
            tone: StatisticsMetricTone.positive,
          ),
          StatisticsMetric(
            label: 'Shared Recipe',
            value: totalPost.toString(),
            tone: StatisticsMetricTone.positive,
          ),
          StatisticsMetric(
            label: 'Top Rated',
            value: topRatedRecipe,
            tone: StatisticsMetricTone.positive,
          ),
          StatisticsMetric(
            label: 'Most Rated',
            value: mostRatedRecipe,
            tone: StatisticsMetricTone.positive,
          ),
        ],
      ),
    ];
  }

  // Handles _topRatedRecipe for this part of the statistics page.
  String _topRatedRecipe(List<_CommunityRecipeStat> recipes) {
    if (recipes.isEmpty) return '-';
    final sorted = [...recipes]
      ..sort((left, right) {
        final ratingCompare = right.averageRating.compareTo(left.averageRating);
        if (ratingCompare != 0) return ratingCompare;
        return right.ratingCount.compareTo(left.ratingCount);
      });
    return sorted.first.name;
  }

  // Handles _topRatedRecipeByRatingDate for this part of the statistics page.
  Future<String> _topRatedRecipeByRatingDate({
    required List<_CommunityRecipeStat> recipes,
    required ({DateTime start, DateTime end}) range,
  }) async {
    if (recipes.isEmpty) return '-';

    final ratedRecipes = <_TodayRecipeRating>[];
    for (final recipe in recipes) {
      final ratings = await firestore
          .collection('recipes')
          .doc(recipe.id)
          .collection('ratings')
          .get();
      var ratingCount = 0;
      var ratingTotal = 0.0;

      for (final rating in ratings.docs) {
        final data = rating.data();
        final ratedAt = _dateTime(data['createdAt'] ?? data['updatedAt']);
        if (ratedAt.isBefore(range.start) || ratedAt.isAfter(range.end)) {
          continue;
        }

        final value = _doubleValue(data['rating']);
        if (value <= 0) continue;
        ratingCount++;
        ratingTotal += value;
      }

      if (ratingCount == 0) continue;
      ratedRecipes.add(
        _TodayRecipeRating(
          recipeName: recipe.name,
          averageRating: ratingTotal / ratingCount,
          ratingCount: ratingCount,
        ),
      );
    }

    if (ratedRecipes.isEmpty) return '-';
    ratedRecipes.sort((left, right) {
      final ratingCompare = right.averageRating.compareTo(left.averageRating);
      if (ratingCompare != 0) return ratingCompare;
      final countCompare = right.ratingCount.compareTo(left.ratingCount);
      if (countCompare != 0) return countCompare;
      return left.recipeName.compareTo(right.recipeName);
    });
    return ratedRecipes.first.recipeName;
  }

  // Handles _mostRatedRecipe for this part of the statistics page.
  String _mostRatedRecipe(List<_CommunityRecipeStat> recipes) {
    if (recipes.isEmpty) return '-';
    final sorted = [...recipes]
      ..sort((left, right) {
        final countCompare = right.ratingCount.compareTo(left.ratingCount);
        if (countCompare != 0) return countCompare;
        return right.averageRating.compareTo(left.averageRating);
      });
    return sorted.first.name;
  }

  // Handles _averagePostedRecipeRating for this part of the statistics page.
  double _averagePostedRecipeRating(List<_CommunityRecipeStat> recipes) {
    if (recipes.isEmpty) return 0;
    final ratingTotal = recipes.fold<double>(
      0,
      (total, recipe) => total + recipe.averageRating,
    );
    return ratingTotal / recipes.length;
  }

  ({DateTime start, DateTime end}) _resolveRange(
    DateTime? startDate,
    DateTime? endDate,
  ) {
    final now = DateTime.now();
    final defaultEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final defaultStart = DateTime(2026, 5);
    final start = _startOfDay(startDate ?? defaultStart);
    final end = _endOfDay(endDate ?? defaultEnd);
    return start.isAfter(end)
        ? (start: _startOfDay(end), end: _endOfDay(start))
        : (start: start, end: end);
  }

  ({DateTime start, DateTime end}) _resolveAdminRange(
    DateTime? startDate,
    DateTime? endDate,
  ) {
    return _resolveRange(startDate, endDate);
  }

  ({DateTime start, DateTime end}) _allTimeRange() {
    return (
      start: DateTime.fromMillisecondsSinceEpoch(0),
      end: DateTime(9999, 12, 31, 23, 59, 59),
    );
  }

  // Handles _startOfDay for this part of the statistics page.
  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Handles _endOfDay for this part of the statistics page.
  DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  // Handles _startOfMonth for this part of the statistics page.
  DateTime _startOfMonth(DateTime date) {
    return DateTime(date.year, date.month);
  }

  // Handles _monthsInRange for this part of the statistics page.
  List<DateTime> _monthsInRange(({DateTime start, DateTime end}) range) {
    final months = <DateTime>[];
    var cursor = _startOfMonth(range.start);
    final end = _startOfMonth(range.end);
    while (!cursor.isAfter(end)) {
      months.add(cursor);
      cursor = DateTime(cursor.year, cursor.month + 1);
    }
    return months;
  }

  // Handles _monthYearLabel for this part of the statistics page.
  String _monthYearLabel(DateTime month) {
    return DateFormat('MMM yyyy').format(month);
  }

  // Handles _nextMonthForForecast for this part of the statistics page.
  DateTime _nextMonthForForecast(List<AdminMonthlyUserStatistic> months) {
    if (months.isEmpty) {
      final now = DateTime.now();
      return DateTime(now.year, now.month + 1);
    }
    final lastMonth = months.last.month;
    return DateTime(lastMonth.year, lastMonth.month + 1);
  }

  // Handles _predictedNextMonthUsers for this part of the statistics page.
  int _predictedNextMonthUsers(List<AdminMonthlyUserStatistic> months) {
    if (months.isEmpty) return 0;
    if (months.length == 1) return months.first.newUsers;

    var totalChange = 0;
    for (var index = 1; index < months.length; index++) {
      totalChange += months[index].newUsers - months[index - 1].newUsers;
    }
    final averageChange = totalChange / (months.length - 1);
    return (months.last.newUsers + averageChange)
        .round()
        .clamp(0, 999999)
        .toInt();
  }

  // Handles _formatGroceryListDuration for this part of the statistics page.
  String _formatGroceryListDuration(Map<String, dynamic> data) {
    final directDuration = data['duration']?.toString().trim();
    if (directDuration != null && directDuration.isNotEmpty) {
      return directDuration;
    }

    final start = _dateTime(data['startDate']);
    final end = _dateTime(data['endDate']);
    if (start.millisecondsSinceEpoch <= 0) return '-';
    final formatter = DateFormat('MMM d');
    if (end.millisecondsSinceEpoch <= 0 ||
        start.year == end.year &&
            start.month == end.month &&
            start.day == end.day) {
      return formatter.format(start);
    }
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }

  // Handles _formatRange for this part of the statistics page.
  String _formatRange(DateTime start, DateTime end) {
    final formatter = DateFormat('MMM d, yyyy');
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }

  // Handles _dateTime for this part of the statistics page.
  DateTime _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is num) {
      final number = value.toInt();
      return DateTime.fromMillisecondsSinceEpoch(
        number > 9999999999 ? number : number * 1000,
      );
    }
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  // Handles _iconForRecipe for this part of the statistics page.
  IconData _iconForRecipe(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('rice')) return Icons.rice_bowl;
    if (lowerName.contains('pasta') || lowerName.contains('noodle')) {
      return Icons.ramen_dining;
    }
    if (lowerName.contains('soup')) return Icons.soup_kitchen;
    if (lowerName.contains('breakfast') || lowerName.contains('toast')) {
      return Icons.breakfast_dining;
    }
    if (lowerName.contains('salad') || lowerName.contains('vegetable')) {
      return Icons.eco;
    }
    return Icons.restaurant;
  }

  // Handles _iconForCategory for this part of the statistics page.
  IconData _iconForCategory(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('asian')) return Icons.rice_bowl;
    if (lowerName.contains('italian') || lowerName.contains('pizza')) {
      return Icons.local_pizza;
    }
    if (lowerName.contains('healthy') || lowerName.contains('vegetarian')) {
      return Icons.eco;
    }
    if (lowerName.contains('breakfast')) return Icons.breakfast_dining;
    return Icons.restaurant_menu;
  }

  // Handles _stringValue for this part of the statistics page.
  String _stringValue(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  // Handles _intValue for this part of the statistics page.
  int _intValue(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  // Handles _doubleValue for this part of the statistics page.
  double _doubleValue(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  // Handles _firstMediaUrl for this part of the statistics page.
  String? _firstMediaUrl(Object? value) {
    if (value is Iterable) {
      for (final item in value) {
        final url = item?.toString().trim() ?? '';
        if (url.isNotEmpty) return url;
      }
    }
    return null;
  }

  // Handles _stringList for this part of the statistics page.
  List<String> _stringList(Object? value) {
    if (value is Iterable) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  // Handles _durationMinutes for this part of the statistics page.
  int _durationMinutes(Object? value) {
    if (value is num) return value.toInt();
    final text = value?.toString() ?? '';
    return int.tryParse(RegExp(r'\d+').firstMatch(text)?.group(0) ?? '') ?? 0;
  }

  // Handles _methodColor for this part of the statistics page.
  Color _methodColor(String method) {
    final lower = method.toLowerCase();
    if (lower.contains('explore')) return const Color(0xFF21AEEA);
    if (lower.contains('library')) return const Color(0xFF54C27A);
    if (lower.contains('ai')) return const Color(0xFFFFB300);
    return const Color(0xFF8E7CF3);
  }

  // Handles _difficultyLevel for this part of the statistics page.
  int _difficultyLevel(Object? value) {
    if (value is num) return value.toInt().clamp(1, 5);
    final text = value?.toString().toLowerCase() ?? '';
    if (text.contains('novice')) return 1;
    if (text.contains('beginner') || text.contains('easy')) return 2;
    if (text.contains('intermediate') || text.contains('medium')) return 3;
    if (text.contains('advanced') || text.contains('hard')) return 4;
    if (text.contains('master')) return 5;
    return int.tryParse(
          RegExp(r'\d+').firstMatch(text)?.group(0) ?? '',
        )?.clamp(1, 5) ??
        1;
  }

  // Handles _methodLabel for this part of the statistics page.
  String _methodLabel(String source) {
    final value = source.toLowerCase();
    if (value.contains('ai')) return 'Generate With AI';
    if (value.contains('library')) return 'From Library';
    if (value.contains('explore') || value.contains('community')) {
      return 'Explore Community';
    }
    if (source.trim().isEmpty) return 'Unknown';
    return source
        .split(RegExp(r'[_\-\s]+'))
        .where(
          (part) => part.isNotEmpty && !RegExp(r'^method\d+$').hasMatch(part),
        )
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  // Handles _methodIcon for this part of the statistics page.
  IconData _methodIcon(String method) {
    final lower = method.toLowerCase();
    if (lower.contains('ai')) return Icons.auto_awesome;
    if (lower.contains('library')) return Icons.bookmark;
    if (lower.contains('explore')) return Icons.public;
    return Icons.restaurant_menu;
  }

  // Handles _difficultyIcon for this part of the statistics page.
  IconData _difficultyIcon(String label) {
    return Icons.star;
  }

  // Handles _difficultyColor for this part of the statistics page.
  Color _difficultyColor(String label) {
    return const Color(0xFF21AEEA);
  }

  // Handles _genderLabel for this part of the statistics page.
  String _genderLabel(Object? value) {
    final lower = value?.toString().trim().toLowerCase() ?? '';
    if (lower.startsWith('m')) return 'Male';
    if (lower.startsWith('f')) return 'Female';
    return 'Prefer not to say';
  }

  // Handles _genderIcon for this part of the statistics page.
  IconData _genderIcon(String label) {
    final lower = label.toLowerCase();
    if (lower == 'male') return Icons.male;
    if (lower == 'female') return Icons.female;
    return Icons.privacy_tip_outlined;
  }

  // Handles _genderColor for this part of the statistics page.
  Color _genderColor(String label) {
    final lower = label.toLowerCase();
    if (lower == 'male') return const Color(0xFF21AEEA);
    if (lower == 'female') return const Color(0xFFFF7A9A);
    return const Color(0xFF8E7CF3);
  }

  // Handles _dietaryIcon for this part of the statistics page.
  IconData _dietaryIcon(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('vegetarian') || lower.contains('vege')) {
      return Icons.eco;
    }
    if (lower.contains('pork') || lower.contains('meat')) {
      return Icons.no_food;
    }
    if (lower.contains('alcohol')) return Icons.local_bar_outlined;
    if (lower.contains('allerg')) return Icons.health_and_safety_outlined;
    return Icons.restaurant_menu;
  }

  // Handles _mealTimeLabel for this part of the statistics page.
  String _mealTimeLabel(String value) {
    final text = value.trim();
    if (text.isEmpty) return 'Meal';
    final lower = text.toLowerCase();
    if (lower.contains('breakfast')) return 'Breakfast';
    if (lower.contains('lunch')) return 'Lunch';
    if (lower.contains('dinner')) return 'Dinner';
    if (lower.contains('snack')) return 'Snack';
    return text;
  }

  // Handles _mealTimeLabelForPlan for this part of the statistics page.
  String _mealTimeLabelForPlan(
    _MealPlanStat plan,
    List<_MealCategoryConfig> categories,
  ) {
    final id = plan.mealCategoryId.trim();
    if (id.isNotEmpty) {
      for (final category in categories) {
        if (category.id == id) return category.name;
      }
    }

    final name = _mealTimeLabel(plan.mealCategoryName);
    for (final category in categories) {
      if (category.name.toLowerCase() == name.toLowerCase()) {
        return category.name;
      }
    }
    return name;
  }

  // Handles _mealTimeIcon for this part of the statistics page.
  IconData _mealTimeIcon(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('breakfast')) return Icons.breakfast_dining;
    if (lower.contains('lunch')) return Icons.lunch_dining;
    if (lower.contains('dinner')) return Icons.dinner_dining;
    if (lower.contains('snack')) return Icons.cookie_outlined;
    return Icons.room_service_outlined;
  }

  // Handles _mealTimeColor for this part of the statistics page.
  Color _mealTimeColor(String value) {
    final lower = value.toLowerCase();
    if (lower.contains('breakfast')) return const Color(0xFF54C27A);
    if (lower.contains('lunch')) return const Color(0xFFFFB300);
    if (lower.contains('dinner')) return const Color(0xFFFF7A59);
    if (lower.contains('snack')) return const Color(0xFF21AEEA);
    return const Color(0xFF8E7CF3);
  }
}

// Handles _MealCategoryConfig for this part of the statistics page.
class _MealCategoryConfig {
  final String id;
  final String name;

  // Handles _MealCategoryConfig for this part of the statistics page.
  const _MealCategoryConfig({required this.id, required this.name});
}

class _MealPlanStat {
  final String id;
  final String plannerUid;
  final String recipeId;
  final String recipeName;
  final String? imageUrl;
  final DateTime date;
  final String source;
  final String mealCategoryId;
  final String mealCategoryName;
  final int cookingTimeMinutes;
  final int difficultyLevel;
  final List<String> categoryIds;
  final List<String> customCategoryIds;

  // Handles _MealPlanStat for this part of the statistics page.
  const _MealPlanStat({
    required this.id,
    required this.plannerUid,
    required this.recipeId,
    required this.recipeName,
    this.imageUrl,
    required this.date,
    required this.source,
    required this.mealCategoryId,
    required this.mealCategoryName,
    required this.cookingTimeMinutes,
    required this.difficultyLevel,
    required this.categoryIds,
    required this.customCategoryIds,
  });
}

// Handles _MostCookedGroup for this part of the statistics page.
class _MostCookedGroup {
  final String recipeName;
  final String? imageUrl;
  int quantity = 0;
  final Map<DateTime, int> plannedByDay = {};

  _MostCookedGroup({required this.recipeName, this.imageUrl});
}

// Handles _FoodGroup for this part of the statistics page.
class _FoodGroup {
  final String label;
  int count = 0;
  String? recipeId;
  String? imageUrl;
  final Map<String, int> detailCounts = {};
  final Map<String, String?> detailImages = {};
  final Map<String, String> detailRecipeIds = {};

  _FoodGroup({required this.label});
}

// Handles _CommunityRecipeStat for this part of the statistics page.
class _CommunityRecipeStat {
  final String id;
  final String name;
  final String creatorUid;
  final double averageRating;
  final int ratingCount;
  final int commentCount;
  final int totalViews;
  final DateTime publishedAt;
  final List<String> categoryIds;
  final List<String> customCategoryIds;
  final int difficultyLevel;
  final String? imageUrl;
  final bool isShared;

  // Handles _CommunityRecipeStat for this part of the statistics page.
  const _CommunityRecipeStat({
    required this.id,
    required this.name,
    required this.creatorUid,
    required this.averageRating,
    required this.ratingCount,
    required this.commentCount,
    required this.totalViews,
    required this.publishedAt,
    required this.categoryIds,
    required this.customCategoryIds,
    required this.difficultyLevel,
    this.imageUrl,
    required this.isShared,
  });

  factory _CommunityRecipeStat.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return _CommunityRecipeStat(
      id: id,
      name: _stringValue(data['name'], fallback: 'Untitled Recipe'),
      creatorUid: _stringValue(
        data['creatorId'] ??
            data['creatorUid'] ??
            data['uid'] ??
            data['userId'] ??
            data['user_id'],
      ),
      averageRating: _doubleValue(data['averageRating']),
      ratingCount: _intValue(data['ratingCount']),
      commentCount: _intValue(data['commentCount']),
      totalViews: _intValue(data['totalViews']),
      publishedAt: _dateTime(
        data['publishedAt'] ??
            data['finalizedAt'] ??
            data['updatedAt'] ??
            data['createdAt'],
      ),
      categoryIds: _stringList(data['categoryIds']),
      customCategoryIds: _stringList(data['customCategoryIds']),
      difficultyLevel: _intValue(data['difficultyLevel']).clamp(1, 5),
      imageUrl: _firstMediaUrl(data['media']),
      isShared:
          data['visibility']?.toString().trim().toLowerCase() == 'public' &&
          data['isFinalized'] != false,
    );
  }

  // Handles _firstMediaUrl for this part of the statistics page.
  static String? _firstMediaUrl(Object? value) {
    if (value is Iterable) {
      for (final item in value) {
        final url = item?.toString().trim() ?? '';
        if (url.isNotEmpty) return url;
      }
    }
    return null;
  }

  // Handles _dateTime for this part of the statistics page.
  static DateTime _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is num) {
      final number = value.toInt();
      return DateTime.fromMillisecondsSinceEpoch(
        number > 9999999999 ? number : number * 1000,
      );
    }
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  // Handles _stringValue for this part of the statistics page.
  static String _stringValue(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  // Handles _intValue for this part of the statistics page.
  static int _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  // Handles _doubleValue for this part of the statistics page.
  static double _doubleValue(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  // Handles _stringList for this part of the statistics page.
  static List<String> _stringList(Object? value) {
    if (value is Iterable) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }
}

// Handles _TodayRecipeRating for this part of the statistics page.
class _TodayRecipeRating {
  final String recipeName;
  final double averageRating;
  final int ratingCount;

  // Handles _TodayRecipeRating for this part of the statistics page.
  const _TodayRecipeRating({
    required this.recipeName,
    required this.averageRating,
    required this.ratingCount,
  });
}

// Handles _RecipeNutritionStat for this part of the statistics page.
class _RecipeNutritionStat {
  final String id;
  final String name;
  final String? imageUrl;
  final DateTime date;
  final _RecipeNutrition nutrition;

  // Handles _RecipeNutritionStat for this part of the statistics page.
  const _RecipeNutritionStat({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.date,
    required this.nutrition,
  });
}

// Handles _RecipeNutrition for this part of the statistics page.
class _RecipeNutrition {
  final int caloriesKcal;
  final int carbohydrateGram;
  final int proteinGram;
  final int fatGram;

  // Handles _RecipeNutrition for this part of the statistics page.
  const _RecipeNutrition({
    required this.caloriesKcal,
    required this.carbohydrateGram,
    required this.proteinGram,
    required this.fatGram,
  });

  const _RecipeNutrition.zero()
    : caloriesKcal = 0,
      carbohydrateGram = 0,
      proteinGram = 0,
      fatGram = 0;
}
