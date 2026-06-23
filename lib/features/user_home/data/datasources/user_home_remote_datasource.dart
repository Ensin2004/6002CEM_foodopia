import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../meal_plan/domain/entities/meal_serving_amount.dart';
import '../../domain/entities/user_home_dashboard.dart';
import '../models/user_home_dashboard_model.dart';

/// Remote data source for user home dashboard.
/// Fetches user data, meal plans, and categories from Firestore.
class UserHomeRemoteDataSource {
  /// FirebaseAuth instance for authentication.
  final FirebaseAuth auth;

  /// Firestore instance for database operations.
  final FirebaseFirestore firestore;

  /// Creates a new user home remote data source instance.
  const UserHomeRemoteDataSource({required this.auth, required this.firestore});

  // =========================================================================
  // DASHBOARD
  // =========================================================================

  /// Retrieves the user home dashboard.
  ///
  /// [fallbackUserName] is used when no user name is available.
  /// Returns a user home dashboard model.
  Future<UserHomeDashboardModel> getDashboard(String fallbackUserName) async {
    // Get the current authenticated user.
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      throw StateError('Sign in to load home.');
    }

    // Resolve the user's name.
    final userName = await _resolveUserName(currentUser, fallbackUserName);

    // Get today's meal sections.
    final sections = await _getTodayMealSections(currentUser.uid);
    final calorieTarget = await _getCalorieTarget(currentUser.uid);

    return UserHomeDashboardModel(
      userName: userName,
      greeting: _timeGreeting(DateTime.now()),
      weather: null,
      quickLinks: _quickLinks,
      mealPlan: sections,
      targetCalories: calorieTarget.targetCalories,
      calorieUnit: calorieTarget.calorieUnit,
      calorieTargetEnabled: calorieTarget.enabled,
    );
  }

  // =========================================================================
  // USER NAME RESOLUTION
  // =========================================================================

  /// Resolves the user's name from various sources.
  Future<String> _resolveUserName(User user, String fallbackUserName) async {
    // Clean the fallback name.
    final fallback = _cleanName(fallbackUserName);

    // Get name from Firebase Auth.
    final authName = _cleanName(user.displayName);

    // Get user document from Firestore.
    final snapshot = await firestore.collection('users').doc(user.uid).get();
    final data = snapshot.data();

    // Try to get name from Firestore.
    if (data != null) {
      // Check full name field.
      final fullName = _cleanName(data['name']);
      if (fullName.isNotEmpty) return fullName;

      // Check first and last name fields.
      final firstName = _cleanName(data['firstName']);
      final lastName = _cleanName(data['lastName']);
      final joinedName = [
        firstName,
        lastName,
      ].where((part) => part.isNotEmpty).join(' ');
      if (joinedName.isNotEmpty) return joinedName;
    }

    // Return the first available name.
    if (authName.isNotEmpty) return authName;
    if (fallback.isNotEmpty) return fallback;

    // Return default name.
    return 'Foodie';
  }

  // =========================================================================
  // MEAL SECTIONS
  // =========================================================================

  /// Retrieves today's meal sections for a user.
  Future<List<UserHomeMealSection>> _getTodayMealSections(String userId) async {
    // Get today's date range.
    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final nextDay = dayStart.add(const Duration(days: 1));

    // Fetch meal categories.
    final categoryDocs = await firestore
        .collection('app_config')
        .doc('meal_categories')
        .collection('items')
        .get()
        .timeout(const Duration(seconds: 8));

    // Parse categories.
    final categories = _categoryOptions(categoryDocs);

    // Fetch today's meal plans.
    final planSnapshot = await firestore
        .collection('meal_plans')
        .where('uid', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
        .where('date', isLessThan: Timestamp.fromDate(nextDay))
        .get()
        .timeout(const Duration(seconds: 8));

    // Build sections from categories and meal plans.
    final docs = planSnapshot.docs;
    final sections = await Future.wait(
      categories.map((category) => _mealSectionFromDocs(category, docs)),
    );
    return sections.where((section) => section.meals.isNotEmpty).toList();
  }

  // =========================================================================
  // CATEGORY PARSING
  // =========================================================================

  /// Parses meal categories from Firestore snapshot.
  List<_MealCategoryOption> _categoryOptions(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    // Sort by sort order.
    final docs = snapshot.docs.toList()
      ..sort((first, second) {
        final left = first.data()['sortOrder'];
        final right = second.data()['sortOrder'];
        return (left is int ? left : 0).compareTo(right is int ? right : 0);
      });

    // Map to category options, filtering inactive ones.
    final categories = docs
        .map((doc) {
          final data = doc.data();
          final name = data['name']?.toString().trim() ?? '';
          final active = data['isActive'] is bool
              ? data['isActive'] as bool
              : true;
          if (!active || name.isEmpty) return null;
          return _MealCategoryOption(id: doc.id, name: name);
        })
        .whereType<_MealCategoryOption>()
        .toList();

    // Return categories or fallback defaults.
    if (categories.isNotEmpty) return categories;
    return const [
      _MealCategoryOption(id: 'breakfast', name: 'Breakfast'),
      _MealCategoryOption(id: 'lunch', name: 'Lunch'),
      _MealCategoryOption(id: 'dinner', name: 'Dinner'),
    ];
  }

  // =========================================================================
  // MEAL SECTION BUILDING
  // =========================================================================

  /// Builds a meal section from category and meal documents.
  Future<UserHomeMealSection> _mealSectionFromDocs(
    _MealCategoryOption category,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    // Filter meals that match the category.
    final mealDocs = docs.where((doc) {
      final data = doc.data();
      final id = data['mealCategoryId']?.toString() ?? '';
      return id == category.id;
    }).toList();
    final meals = await Future.wait(mealDocs.map(_mealFromDoc));

    return UserHomeMealSection(
      mealType: category.name,
      countLabel:
          'Total ${meals.length} ${meals.length == 1 ? 'meal' : 'meals'}',
      accentColor: _accentColor(category.name),
      icon: _mealIcon(category.name),
      meals: meals,
    );
  }

  // =========================================================================
  // MEAL PARSING
  // =========================================================================

  /// Parses a meal from a Firestore document.
  Future<UserHomeMeal> _mealFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final display = await _mealDisplayFromPlan(doc);

    // Get serving label.
    final servings = data['servings'];
    final subtitle = servings is num
        ? MealServingAmount.paxLabel(servings.toDouble())
        : data['servingLabel']?.toString() ?? data['source']?.toString() ?? '';

    return UserHomeMeal(
      mealPlanId: doc.id,
      recipeId: data['recipeId']?.toString() ?? '',
      source: data['source']?.toString() ?? '',
      title: display.title,
      subtitle: subtitle.trim().isEmpty ? 'Planned meal' : subtitle,
      duration: display.durationLabel,
      imagePath: display.imagePath,
      calories: display.calories,
      aiDescription: display.aiDescription,
      aiIngredients: display.aiIngredients,
      aiInstructions: display.aiInstructions,
    );
  }

  Future<_MealDisplayData> _mealDisplayFromPlan(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final recipeId = data['recipeId']?.toString() ?? '';
    final source = data['source']?.toString() ?? '';
    final isAiGenerated = source == 'method3_generate_with_ai';
    final aiGenerated = await _generatedRecipeFromPlan(doc);
    final recipeDoc = recipeId.isEmpty || isAiGenerated
        ? null
        : await firestore.collection('recipes').doc(recipeId).get();
    final recipeData = recipeDoc?.data();
    final media = _stringList(recipeData?['media']);
    final minutes = _intValue(recipeData?['preparationTime']);

    return _MealDisplayData(
      title:
          recipeData?['name']?.toString() ??
          aiGenerated?['title']?.toString() ??
          data['recipeName']?.toString() ??
          'Untitled Meal',
      durationLabel: minutes != null && minutes > 0
          ? '$minutes mins'
          : aiGenerated?['durationLabel']?.toString() ??
                data['durationLabel']?.toString() ??
                'No time set',
      imagePath: media.isNotEmpty
          ? media.first
          : aiGenerated?['imagePath']?.toString().trim().isNotEmpty == true
          ? aiGenerated!['imagePath'].toString()
          : data['recipeImage']?.toString() ?? 'assets/images/meal1.png',
      calories: _caloriesForMeal(data, recipeData, aiGenerated),
      aiDescription: aiGenerated?['description']?.toString() ?? '',
      aiIngredients: _aiIngredientLabels(aiGenerated?['ingredients']),
      aiInstructions: _stringList(aiGenerated?['instructions']),
    );
  }

  Future<Map<String, dynamic>?> _generatedRecipeFromPlan(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final context = await doc.reference
        .collection('ai_context')
        .doc('context')
        .get();
    final generated = context.data()?['generatedRecipe'];
    return generated is Map<String, dynamic> ? generated : null;
  }

  // =========================================================================
  // UTILITY HELPERS
  // =========================================================================

  /// Returns a time-based greeting.
  String _timeGreeting(DateTime dateTime) {
    final hour = dateTime.hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Cleans a string value.
  String _cleanName(Object? value) => value?.toString().trim() ?? '';

  /// Loads daily calorie target settings from meal preferences.
  Future<_CalorieTarget> _getCalorieTarget(String uid) async {
    if (uid.trim().isEmpty) return const _CalorieTarget();

    try {
      final doc = await firestore
          .collection('users')
          .doc(uid)
          .collection('preferences')
          .doc('food_profile')
          .get()
          .timeout(const Duration(seconds: 8));
      final data = doc.data();
      if (data == null) return const _CalorieTarget();

      final targetCalories = _intValue(data['targetCalories']);
      return _CalorieTarget(
        targetCalories: targetCalories,
        calorieUnit: data['calorieUnit']?.toString() ?? 'kcal',
        enabled: data['calorieTargetEnabled'] == true && targetCalories != null,
      );
    } catch (_) {
      return const _CalorieTarget();
    }
  }

  List<String> _stringList(Object? value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  int? _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  /// Resolves calories from AI context, recipe data, or legacy meal plan data.
  int _caloriesForMeal(
    Map<String, dynamic> planData,
    Map<String, dynamic>? recipeData,
    Map<String, dynamic>? aiGenerated,
  ) {
    final aiCalories = _intValue(aiGenerated?['calories']);
    if (aiCalories != null && aiCalories > 0) return aiCalories;

    final nutrition = aiGenerated?['nutrition'];
    final nutritionCalories = nutrition is Map
        ? _intValue(nutrition['calories'] ?? nutrition['energy'])
        : null;
    if (nutritionCalories != null && nutritionCalories > 0) {
      return nutritionCalories;
    }

    final totalNutrients = recipeData?['totalNutrients'];
    final recipeCalories = totalNutrients is Map
        ? _intValue(totalNutrients['calories'] ?? totalNutrients['energy'])
        : _intValue(recipeData?['calories']);
    if (recipeCalories != null && recipeCalories > 0) return recipeCalories;

    return _intValue(planData['calories']) ?? 0;
  }

  /// Converts AI ingredient maps into compact display labels.
  List<String> _aiIngredientLabels(Object? value) {
    if (value is! Iterable) return const [];
    return value
        .map((item) {
          if (item is! Map) return item.toString().trim();
          final name = item['name']?.toString().trim() ?? '';
          final amount = item['amount']?.toString().trim() ?? '';
          final unit = item['unit']?.toString().trim() ?? '';
          final quantity = [
            amount,
            unit,
          ].where((part) => part.isNotEmpty && part != '0').join(' ');
          return [quantity, name].where((part) => part.isNotEmpty).join(' ');
        })
        .where((item) => item.isNotEmpty)
        .toList();
  }

  /// Returns an icon for a meal type.
  IconData _mealIcon(String mealType) {
    final name = mealType.toLowerCase();
    if (name.contains('breakfast')) return Icons.wb_sunny_outlined;
    if (name.contains('lunch')) return Icons.eco_outlined;
    if (name.contains('dinner')) return Icons.nightlight_outlined;
    if (name.contains('snack')) return Icons.local_drink_outlined;
    return Icons.restaurant_menu;
  }

  /// Returns an accent color for a meal type.
  Color _accentColor(String mealType) {
    final name = mealType.toLowerCase();
    if (name.contains('breakfast')) return const Color(0xFFFFF7E1);
    if (name.contains('lunch')) return const Color(0xFFEFF8F1);
    if (name.contains('dinner')) return const Color(0xFFFFF0E7);
    if (name.contains('snack')) return const Color(0xFFF2EEFF);
    return const Color(0xFFEFF4FF);
  }

  // =========================================================================
  // QUICK LINKS
  // =========================================================================

  /// List of quick link options for the home dashboard.
  static const List<UserHomeQuickLink> _quickLinks = [
    UserHomeQuickLink(
      title: 'Explore Recipes',
      icon: Icons.search,
      target: UserHomeQuickLinkTarget.explore,
    ),
    UserHomeQuickLink(
      title: 'Add Recipe',
      icon: Icons.add_circle_outline,
      target: UserHomeQuickLinkTarget.addRecipe,
    ),
    UserHomeQuickLink(
      title: 'Plan Meal',
      icon: Icons.event_note,
      target: UserHomeQuickLinkTarget.mealPlan,
    ),
    UserHomeQuickLink(
      title: 'Try AI',
      icon: Icons.auto_awesome,
      target: UserHomeQuickLinkTarget.tryAi,
    ),
    UserHomeQuickLink(
      title: 'Grocery List',
      icon: Icons.shopping_cart_outlined,
      target: UserHomeQuickLinkTarget.groceryList,
    ),
    UserHomeQuickLink(
      title: 'Statistics',
      icon: Icons.bar_chart,
      target: UserHomeQuickLinkTarget.statistics,
    ),
  ];
}

/// Internal meal category option class.
class _MealCategoryOption {
  /// Category ID.
  final String id;

  /// Category name.
  final String name;

  /// Creates a new meal category option instance.
  const _MealCategoryOption({required this.id, required this.name});
}

class _CalorieTarget {
  final int? targetCalories;
  final String calorieUnit;
  final bool enabled;

  const _CalorieTarget({
    this.targetCalories,
    this.calorieUnit = 'kcal',
    this.enabled = false,
  });
}

class _MealDisplayData {
  final String title;
  final String durationLabel;
  final String imagePath;
  final int calories;
  final String aiDescription;
  final List<String> aiIngredients;
  final List<String> aiInstructions;

  const _MealDisplayData({
    required this.title,
    required this.durationLabel,
    required this.imagePath,
    this.calories = 0,
    this.aiDescription = '',
    this.aiIngredients = const [],
    this.aiInstructions = const [],
  });
}
