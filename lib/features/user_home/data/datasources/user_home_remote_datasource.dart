import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

    return UserHomeDashboardModel(
      userName: userName,
      greeting: _timeGreeting(DateTime.now()),
      weather: null,
      quickLinks: _quickLinks,
      mealPlan: sections,
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
    return categories
        .map((category) => _mealSectionFromDocs(category, docs))
        .where((section) => section.meals.isNotEmpty)
        .toList();
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
  UserHomeMealSection _mealSectionFromDocs(
      _MealCategoryOption category,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      ) {
    // Filter meals that match the category.
    final meals = docs
        .where((doc) {
      final data = doc.data();
      final id = data['mealCategoryId']?.toString() ?? '';
      final name = data['mealCategoryName']?.toString() ?? '';
      return id == category.id ||
          name.toLowerCase() == category.name.toLowerCase();
    })
        .map(_mealFromDoc)
        .toList();

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
  UserHomeMeal _mealFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    // Get serving label.
    final servings = data['servings'];
    final subtitle = servings is num
        ? '${servings.toInt()} Serving Pax'
        : data['servingLabel']?.toString() ?? data['source']?.toString() ?? '';

    return UserHomeMeal(
      title: data['recipeName']?.toString() ?? 'Untitled Meal',
      subtitle: subtitle.trim().isEmpty ? 'Planned meal' : subtitle,
      duration: data['durationLabel']?.toString() ?? 'No time set',
      imagePath: data['recipeImage']?.toString() ?? 'assets/images/meal1.png',
    );
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