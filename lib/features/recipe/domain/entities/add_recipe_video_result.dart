import 'dart:io';

import 'add_recipe_basic_info.dart';
import 'add_recipe_ingredient.dart';
import 'add_recipe_instruction.dart';

/// Editable recipe data produced from a video, split into basic info,
/// ingredients and instructions for the add-recipe flow.
class AddRecipeVideoResult {
  final AddRecipeBasicInfo basicInfo;
  final List<AddRecipeIngredient> ingredients;
  final List<AddRecipeInstruction> instructions;

  const AddRecipeVideoResult({
    required this.basicInfo,
    required this.ingredients,
    required this.instructions,
  });
}

/// Raw AI video recipe draft with generated image prompt and optional image file.
class AddRecipeVideoDraft {
  final String recipeName;
  final String description;
  final String categoryName;
  final int preparationMinutes;
  final int difficultyLevel;
  final int servings;
  final List<AddRecipeVideoIngredient> ingredients;
  final List<String> instructions;
  final String imagePrompt;
  final File? imageFile;

  const AddRecipeVideoDraft({
    required this.recipeName,
    required this.description,
    required this.categoryName,
    required this.preparationMinutes,
    required this.difficultyLevel,
    required this.servings,
    required this.ingredients,
    required this.instructions,
    required this.imagePrompt,
    this.imageFile,
  });
}

/// Ingredient extracted from video analysis before matching to configured units.
class AddRecipeVideoIngredient {
  final String name;
  final double amount;
  final String unit;

  const AddRecipeVideoIngredient({
    required this.name,
    required this.amount,
    required this.unit,
  });
}
