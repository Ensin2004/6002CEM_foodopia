import 'package:flutter/material.dart';

class DifficultyMealStatistics {
  final String dateRange;
  final int totalPost;
  final double averageDifficulty;
  final List<DifficultyMealGroup> groups;

  const DifficultyMealStatistics({
    required this.dateRange,
    required this.totalPost,
    required this.averageDifficulty,
    required this.groups,
  });
}

class DifficultyMealGroup {
  final int difficulty;
  final int recipeCount;
  final Color color;
  final List<DifficultyMealItem> meals;

  const DifficultyMealGroup({
    required this.difficulty,
    required this.recipeCount,
    required this.color,
    required this.meals,
  });
}

class DifficultyMealItem {
  final String name;
  final DateTime date;
  final int quantity;
  final IconData icon;

  const DifficultyMealItem({
    required this.name,
    required this.date,
    required this.quantity,
    required this.icon,
  });
}
