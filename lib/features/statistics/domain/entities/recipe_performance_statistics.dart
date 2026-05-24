class RecipePerformanceStatistics {
  final String dateRange;
  final int totalViews;
  final int totalComments;
  final int totalFavourites;
  final int totalRatings;
  final List<RecipePerformanceItem> recipes;

  const RecipePerformanceStatistics({
    required this.dateRange,
    required this.totalViews,
    required this.totalComments,
    required this.totalFavourites,
    required this.totalRatings,
    required this.recipes,
  });
}

class RecipePerformanceItem {
  final String id;
  final String name;
  final String? imageUrl;
  final int totalViews;
  final int commentCount;
  final int favouriteCount;
  final int ratingCount;
  final DateTime publishedAt;

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
