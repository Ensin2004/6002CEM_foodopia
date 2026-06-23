import '../../domain/entities/library_recipe.dart';

class LibraryRecipeModel extends LibraryRecipe {
  const LibraryRecipeModel({
    required super.id,
    required super.title,
    required super.author,
    required super.publishedAtLabel,
    required super.authorAvatarPath,
    required super.imagePath,
    super.imagePaths,
    required super.description,
    required super.category,
    required super.allergenInfo,
    required super.totalTime,
    required super.difficulty,
    required super.rating,
    required super.ratingCount,
    required super.commentCount,
    required super.totalViews,
    required super.isSelfPublished,
    required super.isFollowingAuthor,
    required super.isPublished,
    super.isModerationHidden,
    required super.ingredients,
    required super.instructionSections,
    required super.nutrition,
    required super.community,
    required super.relatedRecipes,
  });
}
