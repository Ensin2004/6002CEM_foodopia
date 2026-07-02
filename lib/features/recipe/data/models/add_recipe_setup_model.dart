import '../../domain/entities/add_recipe_setup.dart';

/// Firestore-backed setup model for add-recipe categories, allergens, and difficulty labels.
class AddRecipeSetupModel extends AddRecipeSetup {
  const AddRecipeSetupModel({
    required super.categories,
    required super.allergens,
    required super.difficultyLevels,
  });
}
