import 'package:flutter/material.dart';

class MealPlanMethodStatistics {
  final String dateRange;
  final int totalMethodUsed;
  final String topMethod;
  final List<MealPlanMethodGroup> groups;

  const MealPlanMethodStatistics({
    required this.dateRange,
    required this.totalMethodUsed,
    required this.topMethod,
    required this.groups,
  });
}

class MealPlanMethodGroup {
  final String title;
  final int totalUsed;
  final Color color;
  final IconData icon;
  final List<MealPlanMethodItem> meals;

  const MealPlanMethodGroup({
    required this.title,
    required this.totalUsed,
    required this.color,
    required this.icon,
    required this.meals,
  });
}

class MealPlanMethodItem {
  final String recipeName;
  final DateTime date;
  final String mealTime;
  final int quantity;
  final IconData icon;
  final String? imageUrl;

  const MealPlanMethodItem({
    required this.recipeName,
    required this.date,
    required this.mealTime,
    required this.quantity,
    required this.icon,
    this.imageUrl,
  });
}
