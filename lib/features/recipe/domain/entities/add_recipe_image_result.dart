import 'add_recipe_ingredient.dart';
import 'add_recipe_instruction.dart';
import 'add_recipe_video_result.dart';

class AddRecipeImageResult {
  final String recipeName;
  final String description;
  final List<AddRecipeIngredient> ingredients;
  final List<AddRecipeInstruction> instructions;

  const AddRecipeImageResult({
    required this.recipeName,
    required this.description,
    required this.ingredients,
    required this.instructions,
  });
}

class AddRecipeImageDraft {
  final bool isFood;
  final String reason;
  final String recipeName;
  final String description;
  final List<AddRecipeVideoIngredient> ingredients;
  final List<String> instructions;

  const AddRecipeImageDraft({
    required this.isFood,
    required this.reason,
    required this.recipeName,
    required this.description,
    required this.ingredients,
    required this.instructions,
  });
}
