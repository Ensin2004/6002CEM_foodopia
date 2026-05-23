import 'package:flutter/material.dart';

class MealPlannedTimeStatistics {
  final String dateRange;
  final int totalDays;
  final int totalMeals;
  final List<MealPlannedTimeSegment> segments;

  const MealPlannedTimeStatistics({
    required this.dateRange,
    required this.totalDays,
    required this.totalMeals,
    required this.segments,
  });
}

class MealPlannedTimeSegment {
  final String title;
  final int totalTaken;
  final Color color;
  final IconData icon;
  final List<MealPlannedItem> meals;

  const MealPlannedTimeSegment({
    required this.title,
    required this.totalTaken,
    required this.color,
    required this.icon,
    required this.meals,
  });
}

class MealPlannedItem {
  final String name;
  final int amount;
  final DateTime plannedDate;
  final IconData icon;

  const MealPlannedItem({
    required this.name,
    required this.amount,
    required this.plannedDate,
    required this.icon,
  });
}
