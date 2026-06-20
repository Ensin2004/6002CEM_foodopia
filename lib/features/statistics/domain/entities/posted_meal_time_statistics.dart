// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:flutter/material.dart';

// Handles PostedMealTimeStatistics for this part of the statistics page.
class PostedMealTimeStatistics {
  final String dateRange;
  final int totalPost;
  final String mostPostedMealTime;
  final List<PostedMealTimeSegment> segments;

  // Handles PostedMealTimeStatistics for this part of the statistics page.
  const PostedMealTimeStatistics({
    required this.dateRange,
    required this.totalPost,
    required this.mostPostedMealTime,
    required this.segments,
  });
}

// Handles PostedMealTimeSegment for this part of the statistics page.
class PostedMealTimeSegment {
  final String title;
  final int totalPosted;
  final Color color;
  final IconData icon;
  final List<PostedMealTimeItem> meals;

  // Handles PostedMealTimeSegment for this part of the statistics page.
  const PostedMealTimeSegment({
    required this.title,
    required this.totalPosted,
    required this.color,
    required this.icon,
    required this.meals,
  });
}

// Handles PostedMealTimeItem for this part of the statistics page.
class PostedMealTimeItem {
  final String recipeName;
  final DateTime date;
  final int quantity;
  final IconData icon;

  // Handles PostedMealTimeItem for this part of the statistics page.
  const PostedMealTimeItem({
    required this.recipeName,
    required this.date,
    required this.quantity,
    required this.icon,
  });
}
