import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/post_analytic_statistics.dart';
import '../../domain/entities/post_difficulty_statistics.dart';
import '../../domain/entities/recipe_performance_statistics.dart';
import '../../domain/entities/statistics_dashboard.dart';

class StatisticsRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  const StatisticsRemoteDataSource({
    required this.firestore,
    required this.auth,
  });

  Future<List<StatisticsHeroSlide>> getUserCommunityHeroSlides() async {
    final uid = auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return _buildCommunitySlides(const []);

    final recipes = await _getUserSharedRecipes(uid);
    return _buildCommunitySlides(recipes);
  }

  Future<PostAnalyticStatistics> getUserPostAnalytic({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
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

  Future<PostDifficultyStatistics> getUserPostDifficulty({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
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

  Future<RecipePerformanceStatistics> getUserRecipePerformance() async {
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

  Future<int> _recipeFavouriteCount(String recipeId) async {
    try {
      final snapshot = await firestore
          .collectionGroup('saved_recipes')
          .where('recipeId', isEqualTo: recipeId)
          .get();
      if (snapshot.docs.isNotEmpty) return snapshot.docs.length;

      final allSavedSnapshot = await firestore
          .collectionGroup('saved_recipes')
          .get();
      final savedCount = allSavedSnapshot.docs.where((doc) {
        final data = doc.data();
        final savedRecipeId = data['recipeId']?.toString().trim();
        return doc.id == recipeId || savedRecipeId == recipeId;
      }).length;
      if (savedCount > 0) return savedCount;
      return _currentUserFavouriteCount(recipeId);
    } on FirebaseException {
      return _currentUserFavouriteCount(recipeId);
    }
  }

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

  Future<List<_CommunityRecipeStat>> _getUserSharedRecipes(String uid) async {
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
        .where((doc) => _isSharedRecipe(doc.data()))
        .map((doc) => _CommunityRecipeStat.fromFirestore(doc.id, doc.data()))
        .toList();
  }

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

  bool _isSharedRecipe(Map<String, dynamic> data) {
    final visibility = data['visibility']?.toString().trim().toLowerCase();
    return visibility == 'public';
  }

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
    final defaultStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final start = _startOfDay(startDate ?? defaultStart);
    final end = _endOfDay(endDate ?? defaultEnd);
    return start.isAfter(end)
        ? (start: _startOfDay(end), end: _endOfDay(start))
        : (start: start, end: end);
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  String _formatRange(DateTime start, DateTime end) {
    final formatter = DateFormat('MMM d, yyyy');
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }

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

  String _stringValue(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }
}

class _CommunityRecipeStat {
  final String id;
  final String name;
  final double averageRating;
  final int ratingCount;
  final int commentCount;
  final int totalViews;
  final DateTime publishedAt;
  final List<String> categoryIds;
  final List<String> customCategoryIds;
  final int difficultyLevel;
  final String? imageUrl;

  const _CommunityRecipeStat({
    required this.id,
    required this.name,
    required this.averageRating,
    required this.ratingCount,
    required this.commentCount,
    required this.totalViews,
    required this.publishedAt,
    required this.categoryIds,
    required this.customCategoryIds,
    required this.difficultyLevel,
    this.imageUrl,
  });

  factory _CommunityRecipeStat.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return _CommunityRecipeStat(
      id: id,
      name: _stringValue(data['name'], fallback: 'Untitled Recipe'),
      averageRating: _doubleValue(data['averageRating']),
      ratingCount: _intValue(data['ratingCount']),
      commentCount: _intValue(data['commentCount']),
      totalViews: _intValue(data['totalViews']),
      publishedAt: _dateTime(data['updatedAt'] ?? data['createdAt']),
      categoryIds: _stringList(data['categoryIds']),
      customCategoryIds: _stringList(data['customCategoryIds']),
      difficultyLevel: _intValue(data['difficultyLevel']).clamp(1, 5),
      imageUrl: _firstMediaUrl(data['media']),
    );
  }

  static String? _firstMediaUrl(Object? value) {
    if (value is Iterable) {
      for (final item in value) {
        final url = item?.toString().trim() ?? '';
        if (url.isNotEmpty) return url;
      }
    }
    return null;
  }

  static DateTime _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static String _stringValue(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static int _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _doubleValue(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

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
