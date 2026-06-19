// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:flutter/material.dart';

// Handles MealPlanMethodStatistics for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class MealPlanMethodStatistics {
  final String dateRange;
  final int totalMethodUsed;
  final String topMethod;
  final List<MealPlanMethodGroup> groups;

  // Handles MealPlanMethodStatistics for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const MealPlanMethodStatistics({
    required this.dateRange,
    required this.totalMethodUsed,
    required this.topMethod,
    required this.groups,
  });
}

// Handles MealPlanMethodGroup for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class MealPlanMethodGroup {
  final String title;
  final int totalUsed;
  final Color color;
  final IconData icon;
  final List<MealPlanMethodItem> meals;

  // Handles MealPlanMethodGroup for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const MealPlanMethodGroup({
    required this.title,
    required this.totalUsed,
    required this.color,
    required this.icon,
    required this.meals,
  });
}

// Handles MealPlanMethodItem for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class MealPlanMethodItem {
  final String recipeName;
  final DateTime date;
  final String mealTime;
  final int quantity;
  final IconData icon;
  final String? imageUrl;

  // Handles MealPlanMethodItem for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const MealPlanMethodItem({
    required this.recipeName,
    required this.date,
    required this.mealTime,
    required this.quantity,
    required this.icon,
    this.imageUrl,
  });
}
