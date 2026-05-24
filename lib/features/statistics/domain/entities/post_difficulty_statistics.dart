import 'package:flutter/material.dart';

class PostDifficultyStatistics {
  final String dateRange;
  final int totalPost;
  final double averageDifficulty;
  final List<PostDifficultyGroup> groups;

  const PostDifficultyStatistics({
    required this.dateRange,
    required this.totalPost,
    required this.averageDifficulty,
    required this.groups,
  });
}

class PostDifficultyGroup {
  final int difficulty;
  final int postCount;
  final Color color;
  final List<PostDifficultyItem> posts;

  const PostDifficultyGroup({
    required this.difficulty,
    required this.postCount,
    required this.color,
    required this.posts,
  });
}

class PostDifficultyItem {
  final String recipeName;
  final DateTime date;
  final IconData icon;
  final String? imageUrl;

  const PostDifficultyItem({
    required this.recipeName,
    required this.date,
    required this.icon,
    this.imageUrl,
  });
}
