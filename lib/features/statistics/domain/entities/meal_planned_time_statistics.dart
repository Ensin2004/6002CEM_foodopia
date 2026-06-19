// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:flutter/material.dart';

// Handles MealPlannedTimeStatistics for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class MealPlannedTimeStatistics {
  final String dateRange;
  final int totalDays;
  final int totalMeals;
  final List<MealPlannedTimeSegment> segments;

  // Handles MealPlannedTimeStatistics for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const MealPlannedTimeStatistics({
    required this.dateRange,
    required this.totalDays,
    required this.totalMeals,
    required this.segments,
  });
}

// Handles MealPlannedTimeSegment for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class MealPlannedTimeSegment {
  final String title;
  final int totalTaken;
  final Color color;
  final IconData icon;
  final List<MealPlannedItem> meals;

  // Handles MealPlannedTimeSegment for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const MealPlannedTimeSegment({
    required this.title,
    required this.totalTaken,
    required this.color,
    required this.icon,
    required this.meals,
  });
}

// Handles MealPlannedItem for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class MealPlannedItem {
  final String name;
  final int amount;
  final DateTime plannedDate;
  final IconData icon;
  final String? imageUrl;

  // Handles MealPlannedItem for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const MealPlannedItem({
    required this.name,
    required this.amount,
    required this.plannedDate,
    required this.icon,
    this.imageUrl,
  });
}
