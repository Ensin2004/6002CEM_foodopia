// Enumeration of available tabs for filtering recipe lists in the explore view.
enum ExploreRecipeTab { all, popular, recent, following }

// Core domain entity representing a complete recipe with all details.
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
  final double servings;
  final double rating;
  final int ratingCount;
  final int commentCount;
  final int totalViews;
  final DateTime publishedAt;
  final bool isFollowingAuthor;
  final bool isFavourite;
  final bool isCreatedByCurrentUser;
  final bool hasRatedByCurrentUser;
  final bool isModerationHidden;
  final String moderationHiddenReason;
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
    this.isModerationHidden = false,
    this.moderationHiddenReason = '',
    required this.ingredients,
    required this.instructionSections,
    required this.nutrition,
    required this.community,
    required this.relatedRecipes,
  });
}

// Represents an ingredient with nutritional information and metadata.
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
  final double fiberGrams;
  final double waterGrams;
  final List<ExploreNutrientAmount> vitamins;
  final List<ExploreNutrientAmount> minerals;
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
    this.fiberGrams = 0,
    this.waterGrams = 0,
    this.vitamins = const [],
    this.minerals = const [],
    this.ingredientCategoryId = '',
    this.ingredientCategoryName = '',
  });
}

// Groups instruction steps under a titled section.
class ExploreInstructionSection {
  final String title;
  final List<ExploreInstructionStep> steps;

  const ExploreInstructionSection({required this.title, required this.steps});
}

// A single step within an instruction section.
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

// Aggregated nutritional data for a complete recipe.
class ExploreNutrition {
  final int calories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final int fiberGrams;
  final int waterGrams;
  final List<ExploreNutrientAmount> vitamins;
  final List<ExploreNutrientAmount> minerals;

  const ExploreNutrition({
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    this.fiberGrams = 0,
    this.waterGrams = 0,
    this.vitamins = const [],
    this.minerals = const [],
  });
}

// Represents a single nutrient with amount, unit, and daily value reference.
class ExploreNutrientAmount {
  final String key;
  final String label;
  final double amount;
  final String unit;
  final double dailyValue;

  const ExploreNutrientAmount({
    required this.key,
    required this.label,
    required this.amount,
    required this.unit,
    required this.dailyValue,
  });
}

// Community interaction data for a recipe including ratings, reviews, and comments.
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

// Breakdown of ratings by star count (1-5).
class ExploreRatingBreakdown {
  final int stars;
  final int count;

  const ExploreRatingBreakdown({required this.stars, required this.count});
}

// A review left by a user with rating and timestamp.
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

// A comment on a recipe with nested replies and like information.
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

// A reply to a comment or another reply with nested replies.
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

// Represents a recipe category option with custom flag for user-defined categories.
class ExploreRecipeCategoryOption {
  final String id;
  final String name;
  final bool isCustom;

  const ExploreRecipeCategoryOption({
    required this.id,
    required this.name,
    required this.isCustom,
  });

  @override
  bool operator ==(Object other) {
    return other is ExploreRecipeCategoryOption &&
        other.id == id &&
        other.isCustom == isCustom;
  }

  @override
  int get hashCode => Object.hash(id, isCustom);
}

// Compact recipe summary for list views and related recipes.
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

// Summary of a creator's profile for follower lists.
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

// Detailed creator profile including bio, stats, and recipe list.
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
