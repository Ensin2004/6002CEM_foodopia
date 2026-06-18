enum ExploreRecipeTab { all, popular, recent, following }

class ExploreRecipe {
  final String id;
  final String creatorUid;
  final String title;
  final String author;
  final String publishedAtLabel;
  final String authorAvatarPath;
  final int authorFollowerCount;
  final String imagePath;
  final List<String>? imagePaths;
  final String description;
  final List<String> otherNames;
  final String category;
  final List<String> categoryIds;
  final List<String> customCategoryIds;
  final List<String> tags;
  final List<String> ingredientNames;
  final String allergenInfo;
  final String totalTime;
  final String difficulty;
  final int servings;
  final double rating;
  final int ratingCount;
  final int commentCount;
  final int totalViews;
  final DateTime publishedAt;
  final bool isFollowingAuthor;
  final bool isFavourite;
  final bool isCreatedByCurrentUser;
  final bool hasRatedByCurrentUser;
  final List<ExploreIngredient> ingredients;
  final List<ExploreInstructionSection> instructionSections;
  final ExploreNutrition nutrition;
  final ExploreCommunity community;
  final List<ExploreRecipeSummary> relatedRecipes;

  const ExploreRecipe({
    required this.id,
    required this.creatorUid,
    required this.title,
    required this.author,
    required this.publishedAtLabel,
    required this.authorAvatarPath,
    this.authorFollowerCount = 0,
    required this.imagePath,
    this.imagePaths,
    required this.description,
    this.otherNames = const [],
    required this.category,
    this.categoryIds = const [],
    this.customCategoryIds = const [],
    this.tags = const [],
    this.ingredientNames = const [],
    required this.allergenInfo,
    required this.totalTime,
    required this.difficulty,
    this.servings = 1,
    required this.rating,
    required this.ratingCount,
    required this.commentCount,
    required this.totalViews,
    required this.publishedAt,
    required this.isFollowingAuthor,
    this.isFavourite = false,
    required this.isCreatedByCurrentUser,
    this.hasRatedByCurrentUser = false,
    required this.ingredients,
    required this.instructionSections,
    required this.nutrition,
    required this.community,
    required this.relatedRecipes,
  });
}

class ExploreIngredient {
  final String name;
  final String amount;
  final String calories;
  final String imagePath;
  final double nutritionPercent;
  final double caloriesValue;
  final double carbsGrams;
  final double proteinGrams;
  final double fatGrams;
  final String ingredientCategoryId;
  final String ingredientCategoryName;

  const ExploreIngredient({
    required this.name,
    required this.amount,
    required this.calories,
    required this.imagePath,
    required this.nutritionPercent,
    this.caloriesValue = 0,
    this.carbsGrams = 0,
    this.proteinGrams = 0,
    this.fatGrams = 0,
    this.ingredientCategoryId = '',
    this.ingredientCategoryName = '',
  });
}

class ExploreInstructionSection {
  final String title;
  final List<ExploreInstructionStep> steps;

  const ExploreInstructionSection({required this.title, required this.steps});
}

class ExploreInstructionStep {
  final String title;
  final String description;
  final String imagePath;

  const ExploreInstructionStep({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

class ExploreNutrition {
  final int calories;
  final int carbsGrams;
  final int proteinGrams;
  final int fatGrams;

  const ExploreNutrition({
    required this.calories,
    required this.carbsGrams,
    required this.proteinGrams,
    required this.fatGrams,
  });
}

class ExploreCommunity {
  final String authorBio;
  final List<ExploreRatingBreakdown> ratingBreakdown;
  final List<ExploreReview> reviews;
  final List<ExploreComment> comments;

  const ExploreCommunity({
    required this.authorBio,
    required this.ratingBreakdown,
    required this.reviews,
    required this.comments,
  });
}

class ExploreRatingBreakdown {
  final int stars;
  final int count;

  const ExploreRatingBreakdown({required this.stars, required this.count});
}

class ExploreReview {
  final String author;
  final String avatarPath;
  final String timeAgo;
  final DateTime createdAt;
  final double rating;

  const ExploreReview({
    required this.author,
    required this.avatarPath,
    required this.timeAgo,
    required this.createdAt,
    required this.rating,
  });
}

class ExploreComment {
  final String id;
  final String author;
  final String avatarPath;
  final String timeAgo;
  final DateTime createdAt;
  final String content;
  final int likes;
  final bool isLiked;
  final List<ExploreCommentReply> replies;

  const ExploreComment({
    required this.id,
    required this.author,
    required this.avatarPath,
    required this.timeAgo,
    required this.createdAt,
    required this.content,
    required this.likes,
    this.isLiked = false,
    this.replies = const [],
  });
}

class ExploreCommentReply {
  final String id;
  final String documentPath;
  final String author;
  final String avatarPath;
  final String timeAgo;
  final DateTime createdAt;
  final String content;
  final int likes;
  final bool isLiked;
  final List<ExploreCommentReply> replies;

  const ExploreCommentReply({
    required this.id,
    required this.documentPath,
    required this.author,
    required this.avatarPath,
    required this.timeAgo,
    required this.createdAt,
    required this.content,
    required this.likes,
    this.isLiked = false,
    this.replies = const [],
  });
}

class ExploreRecipeCategoryOption {
  final String id;
  final String name;
  final bool isCustom;

  const ExploreRecipeCategoryOption({
    required this.id,
    required this.name,
    required this.isCustom,
  });
}

class ExploreRecipeSummary {
  final String id;
  final String title;
  final String imagePath;

  const ExploreRecipeSummary({
    required this.id,
    required this.title,
    required this.imagePath,
  });
}

class ExploreCreatorSummary {
  final String uid;
  final String name;
  final String avatarPath;
  final int followerCount;
  final bool isFollowing;

  const ExploreCreatorSummary({
    required this.uid,
    required this.name,
    required this.avatarPath,
    required this.followerCount,
    this.isFollowing = true,
  });
}

class ExploreCreatorDetail {
  final ExploreCreatorSummary summary;
  final String bio;
  final int postCount;
  final int followingCount;
  final bool isFollowing;
  final List<ExploreRecipe> recipes;

  const ExploreCreatorDetail({
    required this.summary,
    required this.bio,
    required this.postCount,
    required this.followingCount,
    required this.isFollowing,
    required this.recipes,
  });
}
