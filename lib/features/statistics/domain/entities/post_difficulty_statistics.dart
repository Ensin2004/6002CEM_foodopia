import 'package:flutter/material.dart';

// Handles PostDifficultyStatistics for this part of the statistics page.
class PostDifficultyStatistics {
  final String dateRange;
  final int totalPost;
  final double averageDifficulty;
  final List<PostDifficultyGroup> groups;

  // Handles PostDifficultyStatistics for this part of the statistics page.
  const PostDifficultyStatistics({
    required this.dateRange,
    required this.totalPost,
    required this.averageDifficulty,
    required this.groups,
  });
}

// Handles PostDifficultyGroup for this part of the statistics page.
class PostDifficultyGroup {
  final int difficulty;
  final int postCount;
  final Color color;
  final List<PostDifficultyItem> posts;

  // Handles PostDifficultyGroup for this part of the statistics page.
  const PostDifficultyGroup({
    required this.difficulty,
    required this.postCount,
    required this.color,
    required this.posts,
  });
}

// Handles PostDifficultyItem for this part of the statistics page.
class PostDifficultyItem {
  final String recipeName;
  final DateTime date;
  final IconData icon;
  final String? imageUrl;

  // Handles PostDifficultyItem for this part of the statistics page.
  const PostDifficultyItem({
    required this.recipeName,
    required this.date,
    required this.icon,
    this.imageUrl,
  });
}
