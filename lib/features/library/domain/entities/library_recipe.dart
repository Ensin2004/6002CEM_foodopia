// Defines the available tabs for filtering recipes in the library.
// Recipes published for everyone to see
// Personal/draft recipes only visible to the author
// Recipes the user has marked as favourites
enum LibraryRecipeTab { public, private, favourites }

// Represents a complete recipe in the library
// Contains all detailed information about a recipe
class LibraryRecipe {
  final String id;
  final String title;
  final String author;
  final String publishedAtLabel;
  final String authorAvatarPath;
  final String imagePath;
  final List<String>? imagePaths;
  final String description;
  final String category;
  final String allergenInfo;
  final String totalTime;
  final String difficulty;
  final int servings;
  final double rating;
  final int ratingCount;
  final int commentCount;
  final int totalViews;
  final bool isSelfPublished;
  final bool isFollowingAuthor;
  final bool isPublished;
  final bool isModerationHidden;
  final String moderationHiddenReason;
  final List<LibraryIngredient> ingredients;
  final List<LibraryInstructionSection> instructionSections;
  final LibraryNutrition nutrition;
  final LibraryCommunity community;
  final List<LibraryRecipeSummary> relatedRecipes;

  const LibraryRecipe({
    required this.id,
    required this.title,
    required this.author,
    required this.publishedAtLabel,
    required this.authorAvatarPath,
    required this.imagePath,
    this.imagePaths,
    required this.description,
    required this.category,
    required this.allergenInfo,
    required this.totalTime,
    required this.difficulty,
    this.servings = 1,
    required this.rating,
    required this.ratingCount,
    required this.commentCount,
    required this.totalViews,
    required this.isSelfPublished,
    required this.isFollowingAuthor,
    required this.isPublished,
    this.isModerationHidden = false,
    this.moderationHiddenReason = '',
    required this.ingredients,
    required this.instructionSections,
    required this.nutrition,
    required this.community,
    required this.relatedRecipes,
  });
}

// Represents an ingredient used in a recipe
class LibraryIngredient {
  final String name;
  final String amount;
  final String calories;
  final String imagePath;
  final double nutritionPercent;

  const LibraryIngredient({
    required this.name,
    required this.amount,
    required this.calories,
    required this.imagePath,
    required this.nutritionPercent,
  });
}

// Represents a section of cooking instructions
// Each section contains a title and a list of steps within that section
class LibraryInstructionSection {
  final String title;
  final List<LibraryInstructionStep> steps;

  const LibraryInstructionSection({required this.title, required this.steps});
}

class LibraryInstructionStep {
  final String title;
  final String description;
  final String imagePath;

  const LibraryInstructionStep({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

// Represents nutritional information for a recipe per serving
class LibraryNutrition {
  final int calories;
  final int carbsGrams;
  final int proteinGrams;
  final int fatGrams;

  const LibraryNutrition({
    required this.calories,
    required this.carbsGrams,
    required this.proteinGrams,
    required this.fatGrams,
  });
}

// Represents community engagement data for a recipe
// Author biography, rating, reviews and comments
class LibraryCommunity {
  final String authorBio;
  final List<LibraryRatingBreakdown> ratingBreakdown;
  final List<LibraryReview> reviews;
  final List<LibraryComment> comments;

  const LibraryCommunity({
    required this.authorBio,
    required this.ratingBreakdown,
    required this.reviews,
    required this.comments,
  });
}

// Represents a breakdown of ratings by star count.
class LibraryRatingBreakdown {
  final int stars;
  final int count;

  const LibraryRatingBreakdown({required this.stars, required this.count});
}

// Represents a user review of a recipe.
class LibraryReview {
  final String author;
  final String avatarPath;
  final String timeAgo;
  final double rating;

  const LibraryReview({
    required this.author,
    required this.avatarPath,
    required this.timeAgo,
    required this.rating,
  });
}

// Represents a user comment on a recipe.
class LibraryComment {
  final String author;
  final String avatarPath;
  final String timeAgo;
  final String content;
  final int likes;

  const LibraryComment({
    required this.author,
    required this.avatarPath,
    required this.timeAgo,
    required this.content,
    required this.likes,
  });
}

// Represents a summarized version of a recipe for preview/list views.
class LibraryRecipeSummary {
  final String id;
  final String title;
  final String imagePath;

  const LibraryRecipeSummary({
    required this.id,
    required this.title,
    required this.imagePath,
  });
}
