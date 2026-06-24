import 'package:flutter/material.dart';

// Handles PostAnalyticSortOrder for this part of the statistics page.
enum PostAnalyticSortOrder {
  highestRating,
  lowestRating,
  mostRating,
  leastRating,
}

// Handles PostAnalyticStatistics for this part of the statistics page.
class PostAnalyticStatistics {
  final String dateRange;
  final int totalPost;
  final double averageRating;
  final List<PostRatingItem> posts;
  final List<PostRatingCategory> categories;

  // Handles PostAnalyticStatistics for this part of the statistics page.
  const PostAnalyticStatistics({
    required this.dateRange,
    required this.totalPost,
    required this.averageRating,
    required this.posts,
    required this.categories,
  });
}

// Handles PostRatingItem for this part of the statistics page.
class PostRatingItem {
  final String? id;
  final String name;
  final double rating;
  final int ratingCount;
  final IconData icon;
  final String? imageUrl;

  // Handles PostRatingItem for this part of the statistics page.
  const PostRatingItem({
    this.id,
    required this.name,
    required this.rating,
    required this.ratingCount,
    required this.icon,
    this.imageUrl,
  });
}

// Handles PostRatingCategory for this part of the statistics page.
class PostRatingCategory {
  final String name;
  final double averageRating;
  final int ratedDishCount;
  final IconData icon;
  final List<PostRatingItem> dishes;

  // Handles PostRatingCategory for this part of the statistics page.
  const PostRatingCategory({
    required this.name,
    required this.averageRating,
    required this.ratedDishCount,
    required this.icon,
    required this.dishes,
  });
}
