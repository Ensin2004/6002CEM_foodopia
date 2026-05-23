import 'package:flutter/material.dart';

class PostedMealTimeStatistics {
  final String dateRange;
  final int totalPost;
  final String mostPostedMealTime;
  final List<PostedMealTimeSegment> segments;

  const PostedMealTimeStatistics({
    required this.dateRange,
    required this.totalPost,
    required this.mostPostedMealTime,
    required this.segments,
  });
}

class PostedMealTimeSegment {
  final String title;
  final int totalPosted;
  final Color color;
  final IconData icon;
  final List<PostedMealTimeItem> meals;

  const PostedMealTimeSegment({
    required this.title,
    required this.totalPosted,
    required this.color,
    required this.icon,
    required this.meals,
  });
}

class PostedMealTimeItem {
  final String recipeName;
  final DateTime date;
  final int quantity;
  final IconData icon;

  const PostedMealTimeItem({
    required this.recipeName,
    required this.date,
    required this.quantity,
    required this.icon,
  });
}
