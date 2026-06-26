import '../../domain/entities/library_recipe.dart';

// Extends domain entity used in data layer like API responses or database mapping
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
    super.servings,
    required super.rating,
    required super.ratingCount,
    required super.commentCount,
    required super.totalViews,
    required super.isSelfPublished,
    required super.isFollowingAuthor,
    required super.isPublished,
    super.isModerationHidden,
    super.moderationHiddenReason,
    required super.ingredients,
    required super.instructionSections,
    required super.nutrition,
    required super.community,
    required super.relatedRecipes,
  });
}
