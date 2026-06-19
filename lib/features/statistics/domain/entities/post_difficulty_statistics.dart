// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:flutter/material.dart';

// Handles PostDifficultyStatistics for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class PostDifficultyStatistics {
  final String dateRange;
  final int totalPost;
  final double averageDifficulty;
  final List<PostDifficultyGroup> groups;

  // Handles PostDifficultyStatistics for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const PostDifficultyStatistics({
    required this.dateRange,
    required this.totalPost,
    required this.averageDifficulty,
    required this.groups,
  });
}

// Handles PostDifficultyGroup for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class PostDifficultyGroup {
  final int difficulty;
  final int postCount;
  final Color color;
  final List<PostDifficultyItem> posts;

  // Handles PostDifficultyGroup for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const PostDifficultyGroup({
    required this.difficulty,
    required this.postCount,
    required this.color,
    required this.posts,
  });
}

// Handles PostDifficultyItem for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class PostDifficultyItem {
  final String recipeName;
  final DateTime date;
  final IconData icon;
  final String? imageUrl;

  // Handles PostDifficultyItem for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const PostDifficultyItem({
    required this.recipeName,
    required this.date,
    required this.icon,
    this.imageUrl,
  });
}
