import 'package:flutter/material.dart';

class CookingTimeStatistics {
  final String dateRange;
  final int totalMealPlanned;
  final int totalCookingMinutes;
  final List<CookingTimeDay> days;

  const CookingTimeStatistics({
    required this.dateRange,
    required this.totalMealPlanned,
    required this.totalCookingMinutes,
    required this.days,
  });
}

class CookingTimeDay {
  final DateTime date;
  final String label;
  final int totalMeals;
  final int totalCookingMinutes;
  final List<CookingTimeMeal> meals;

  const CookingTimeDay({
    required this.date,
    required this.label,
    required this.totalMeals,
    required this.totalCookingMinutes,
    required this.meals,
  });
}

class CookingTimeMeal {
  final String name;
  final int cookingMinutes;
  final int quantity;
  final IconData icon;
  final String? imageUrl;

  const CookingTimeMeal({
    required this.name,
    required this.cookingMinutes,
    required this.quantity,
    required this.icon,
    this.imageUrl,
  });
}
