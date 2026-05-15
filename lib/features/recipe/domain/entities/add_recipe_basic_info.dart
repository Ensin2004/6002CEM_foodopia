import 'dart:io';

class AddRecipeBasicInfo {
  final List<File> mediaFiles;
  final String recipeName;
  final List<String> otherNames;
  final List<String> categories;
  final int preparationMinutes;
  final int difficultyLevel;
  final int servings;
  final List<String> allergens;

  const AddRecipeBasicInfo({
    required this.mediaFiles,
    required this.recipeName,
    required this.otherNames,
    required this.categories,
    required this.preparationMinutes,
    required this.difficultyLevel,
    required this.servings,
    required this.allergens,
  });
}
