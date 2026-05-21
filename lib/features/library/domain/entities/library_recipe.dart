enum LibraryRecipeTab { public, private, favourites }

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
  final double rating;
  final int ratingCount;
  final int commentCount;
  final bool isSelfPublished;
  final bool isFollowingAuthor;
  final bool isPublished;
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
    required this.rating,
    required this.ratingCount,
    required this.commentCount,
    required this.isSelfPublished,
    required this.isFollowingAuthor,
    required this.isPublished,
    required this.ingredients,
    required this.instructionSections,
    required this.nutrition,
    required this.community,
    required this.relatedRecipes,
  });
}

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

class LibraryRatingBreakdown {
  final int stars;
  final int count;

  const LibraryRatingBreakdown({required this.stars, required this.count});
}

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
