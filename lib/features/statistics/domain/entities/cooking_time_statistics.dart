import 'package:flutter/material.dart';

// Handles CookingTimeStatistics for this part of the statistics page.
class CookingTimeStatistics {
  final String dateRange;
  final int totalMealPlanned;
  final int totalCookingMinutes;
  final List<CookingTimeDay> days;

  // Handles CookingTimeStatistics for this part of the statistics page.
  const CookingTimeStatistics({
    required this.dateRange,
    required this.totalMealPlanned,
    required this.totalCookingMinutes,
    required this.days,
  });
}

// Handles CookingTimeDay for this part of the statistics page.
class CookingTimeDay {
  final DateTime date;
  final String label;
  final int totalMeals;
  final int totalCookingMinutes;
  final List<CookingTimeMeal> meals;

  // Handles CookingTimeDay for this part of the statistics page.
  const CookingTimeDay({
    required this.date,
    required this.label,
    required this.totalMeals,
    required this.totalCookingMinutes,
    required this.meals,
  });
}

// Handles CookingTimeMeal for this part of the statistics page.
class CookingTimeMeal {
  final String name;
  final int cookingMinutes;
  final int quantity;
  final IconData icon;
  final String? imageUrl;

  // Handles CookingTimeMeal for this part of the statistics page.
  const CookingTimeMeal({
    required this.name,
    required this.cookingMinutes,
    required this.quantity,
    required this.icon,
    this.imageUrl,
  });
}
