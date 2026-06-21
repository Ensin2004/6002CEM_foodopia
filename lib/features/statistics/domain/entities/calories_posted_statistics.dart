// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:flutter/material.dart';

// Handles CaloriesPostedStatistics for this part of the statistics page.
class CaloriesPostedStatistics {
  final String dateRange;
  final int totalPost;
  final int averageCaloriesKcal;
  final int averageCarbohydrateGram;
  final int averageProteinGram;
  final int averageFatGram;
  final List<CaloriesPostedDay> dailyPosts;

  // Handles CaloriesPostedStatistics for this part of the statistics page.
  const CaloriesPostedStatistics({
    required this.dateRange,
    required this.totalPost,
    required this.averageCaloriesKcal,
    required this.averageCarbohydrateGram,
    required this.averageProteinGram,
    this.averageFatGram = 0,
    required this.dailyPosts,
  });
}

// Handles CaloriesPostedDay for this part of the statistics page.
class CaloriesPostedDay {
  final DateTime date;
  final String weekdayLabel;
  final int totalPost;
  final int totalCaloriesKcal;
  final int totalCarbohydrateGram;
  final int totalProteinGram;
  final int totalFatGram;
  final List<CaloriesPostedItem> posts;

  // Handles CaloriesPostedDay for this part of the statistics page.
  const CaloriesPostedDay({
    required this.date,
    required this.weekdayLabel,
    required this.totalPost,
    required this.totalCaloriesKcal,
    required this.totalCarbohydrateGram,
    required this.totalProteinGram,
    this.totalFatGram = 0,
    required this.posts,
  });
}

// Handles CaloriesPostedItem for this part of the statistics page.
class CaloriesPostedItem {
  final String recipeName;
  final int caloriesKcal;
  final int carbohydrateGram;
  final int proteinGram;
  final int fatGram;
  final IconData icon;
  final String? imageUrl;

  // Handles CaloriesPostedItem for this part of the statistics page.
  const CaloriesPostedItem({
    required this.recipeName,
    required this.caloriesKcal,
    required this.carbohydrateGram,
    required this.proteinGram,
    this.fatGram = 0,
    required this.icon,
    this.imageUrl,
  });
}
