import 'package:flutter/material.dart';

// Handles CaloriesDisplayUnit for this part of the statistics page.
enum CaloriesDisplayUnit { kcal, cal }

class CaloriesIntakeStatistics {
  final String dateRange;
  final int totalMeal;
  final int averageCaloriesKcal;
  final List<CaloriesDailyIntake> dailyIntakes;

  // Handles CaloriesIntakeStatistics for this part of the statistics page.
  const CaloriesIntakeStatistics({
    required this.dateRange,
    required this.totalMeal,
    required this.averageCaloriesKcal,
    required this.dailyIntakes,
  });
}

// Handles CaloriesDailyIntake for this part of the statistics page.
class CaloriesDailyIntake {
  final DateTime date;
  final String weekdayLabel;
  final int totalPlannedMeal;
  final int totalCaloriesKcal;
  final int totalCarbohydrateGram;
  final int totalProteinGram;
  final int totalFatGram;
  final List<CaloriesMealItem> meals;

  // Handles CaloriesDailyIntake for this part of the statistics page.
  const CaloriesDailyIntake({
    required this.date,
    required this.weekdayLabel,
    required this.totalPlannedMeal,
    required this.totalCaloriesKcal,
    required this.totalCarbohydrateGram,
    required this.totalProteinGram,
    this.totalFatGram = 0,
    required this.meals,
  });
}

// Handles CaloriesMealItem for this part of the statistics page.
class CaloriesMealItem {
  final String name;
  final int caloriesKcal;
  final int carbohydrateGram;
  final int proteinGram;
  final int fatGram;
  final IconData icon;
  final String? imageUrl;

  // Handles CaloriesMealItem for this part of the statistics page.
  const CaloriesMealItem({
    required this.name,
    required this.caloriesKcal,
    required this.carbohydrateGram,
    required this.proteinGram,
    this.fatGram = 0,
    required this.icon,
    this.imageUrl,
  });
}
