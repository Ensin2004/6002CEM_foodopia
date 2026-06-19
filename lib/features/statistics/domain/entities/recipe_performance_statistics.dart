// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
// Handles RecipePerformanceStatistics for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class RecipePerformanceStatistics {
  final String dateRange;
  final int totalViews;
  final int totalComments;
  final int totalFavourites;
  final int totalRatings;
  final List<RecipePerformanceItem> recipes;

  // Handles RecipePerformanceStatistics for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const RecipePerformanceStatistics({
    required this.dateRange,
    required this.totalViews,
    required this.totalComments,
    required this.totalFavourites,
    required this.totalRatings,
    required this.recipes,
  });
}

// Handles RecipePerformanceItem for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class RecipePerformanceItem {
  final String id;
  final String name;
  final String? imageUrl;
  final int totalViews;
  final int commentCount;
  final int favouriteCount;
  final int ratingCount;
  final DateTime publishedAt;

  // Handles RecipePerformanceItem for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  const RecipePerformanceItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.totalViews,
    required this.commentCount,
    required this.favouriteCount,
    required this.ratingCount,
    required this.publishedAt,
  });
}
