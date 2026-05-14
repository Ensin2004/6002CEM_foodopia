enum ExploreRecipeTab { all, popular, recent, following }

class ExploreRecipe {
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
  final double rating;
  final int ratingCount;
  final int commentCount;
  final bool isFollowingAuthor;
  final List<ExploreIngredient> ingredients;
  final List<ExploreInstructionSection> instructionSections;
  final ExploreNutrition nutrition;
  final ExploreCommunity community;
  final List<ExploreRecipeSummary> relatedRecipes;

  const ExploreRecipe({
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
    required this.rating,
    required this.ratingCount,
    required this.commentCount,
    required this.isFollowingAuthor,
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

  const ExploreIngredient({
    required this.name,
    required this.amount,
    required this.calories,
    required this.imagePath,
    required this.nutritionPercent,
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
  final double rating;

  const ExploreReview({
    required this.author,
    required this.avatarPath,
    required this.timeAgo,
    required this.rating,
  });
}

class ExploreComment {
  final String author;
  final String avatarPath;
  final String timeAgo;
  final String content;
  final int likes;

  const ExploreComment({
    required this.author,
    required this.avatarPath,
    required this.timeAgo,
    required this.content,
    required this.likes,
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
