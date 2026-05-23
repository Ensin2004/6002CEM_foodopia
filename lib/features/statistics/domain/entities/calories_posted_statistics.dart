import 'package:flutter/material.dart';

class CaloriesPostedStatistics {
  final String dateRange;
  final int totalPost;
  final int averageCaloriesKcal;
  final List<CaloriesPostedDay> dailyPosts;

  const CaloriesPostedStatistics({
    required this.dateRange,
    required this.totalPost,
    required this.averageCaloriesKcal,
    required this.dailyPosts,
  });
}

class CaloriesPostedDay {
  final DateTime date;
  final String weekdayLabel;
  final int totalPost;
  final int totalCaloriesKcal;
  final List<CaloriesPostedItem> posts;

  const CaloriesPostedDay({
    required this.date,
    required this.weekdayLabel,
    required this.totalPost,
    required this.totalCaloriesKcal,
    required this.posts,
  });
}

class CaloriesPostedItem {
  final String recipeName;
  final int caloriesKcal;
  final IconData icon;

  const CaloriesPostedItem({
    required this.recipeName,
    required this.caloriesKcal,
    required this.icon,
  });
}
