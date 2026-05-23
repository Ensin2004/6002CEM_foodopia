import 'dart:io';

class AddRecipeBasicInfo {
  final String? recipeId;
  final List<File> mediaFiles;
  final List<String> existingMediaUrls;
  final String recipeName;
  final String description;
  final List<String> otherNames;
  final List<String> categoryIds;
  final List<String> customCategories;
  final int preparationMinutes;
  final int difficultyLevel;
  final int servings;
  final List<String> allergenIds;
  final List<String> customAllergens;
  final String visibility;
  final bool isAiGenerated;

  const AddRecipeBasicInfo({
    this.recipeId,
    required this.mediaFiles,
    this.existingMediaUrls = const [],
    required this.recipeName,
    required this.description,
    required this.otherNames,
    required this.categoryIds,
    required this.customCategories,
    required this.preparationMinutes,
    required this.difficultyLevel,
    required this.servings,
    required this.allergenIds,
    required this.customAllergens,
    this.visibility = 'private',
    this.isAiGenerated = false,
  });
}
