// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:flutter/material.dart';

// Handles DifficultyMealStatistics for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class DifficultyMealStatistics {
  final String dateRange;
  final int totalPost;
  final double averageDifficulty;
  final List<DifficultyMealGroup> groups;

  // Handles DifficultyMealStatistics for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const DifficultyMealStatistics({
    required this.dateRange,
    required this.totalPost,
    required this.averageDifficulty,
    required this.groups,
  });
}

// Handles DifficultyMealGroup for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class DifficultyMealGroup {
  final int difficulty;
  final int recipeCount;
  final Color color;
  final List<DifficultyMealItem> meals;

  // Handles DifficultyMealGroup for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const DifficultyMealGroup({
    required this.difficulty,
    required this.recipeCount,
    required this.color,
    required this.meals,
  });
}

// Handles DifficultyMealItem for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class DifficultyMealItem {
  final String name;
  final DateTime date;
  final int quantity;
  final IconData icon;
  final String? imageUrl;

  // Handles DifficultyMealItem for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const DifficultyMealItem({
    required this.name,
    required this.date,
    required this.quantity,
    required this.icon,
    this.imageUrl,
  });
}
