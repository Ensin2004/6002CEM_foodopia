import 'package:flutter/material.dart';

enum CaloriesDisplayUnit { kcal, cal }

class CaloriesIntakeStatistics {
  final String dateRange;
  final int totalMeal;
  final int averageCaloriesKcal;
  final List<CaloriesDailyIntake> dailyIntakes;

  const CaloriesIntakeStatistics({
    required this.dateRange,
    required this.totalMeal,
    required this.averageCaloriesKcal,
    required this.dailyIntakes,
  });
}

class CaloriesDailyIntake {
  final DateTime date;
  final String weekdayLabel;
  final int totalPlannedMeal;
  final int totalCaloriesKcal;
  final List<CaloriesMealItem> meals;

  const CaloriesDailyIntake({
    required this.date,
    required this.weekdayLabel,
    required this.totalPlannedMeal,
    required this.totalCaloriesKcal,
    required this.meals,
  });
}

class CaloriesMealItem {
  final String name;
  final int caloriesKcal;
  final IconData icon;

  const CaloriesMealItem({
    required this.name,
    required this.caloriesKcal,
    required this.icon,
  });
}
