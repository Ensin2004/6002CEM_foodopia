import 'package:flutter/material.dart';

enum PostAnalyticSortOrder {
  highestRating,
  lowestRating,
  mostRating,
  leastRating,
}

class PostAnalyticStatistics {
  final String dateRange;
  final int totalPost;
  final double averageRating;
  final List<PostRatingItem> posts;
  final List<PostRatingCategory> categories;

  const PostAnalyticStatistics({
    required this.dateRange,
    required this.totalPost,
    required this.averageRating,
    required this.posts,
    required this.categories,
  });
}

class PostRatingItem {
  final String name;
  final double rating;
  final int ratingCount;
  final IconData icon;
  final String? imageUrl;

  const PostRatingItem({
    required this.name,
    required this.rating,
    required this.ratingCount,
    required this.icon,
    this.imageUrl,
  });
}

class PostRatingCategory {
  final String name;
  final double averageRating;
  final int ratedDishCount;
  final IconData icon;
  final List<PostRatingItem> dishes;

  const PostRatingCategory({
    required this.name,
    required this.averageRating,
    required this.ratedDishCount,
    required this.icon,
    required this.dishes,
  });
}
