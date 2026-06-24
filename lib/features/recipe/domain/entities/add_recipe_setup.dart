import 'add_recipe_option.dart';

/// Setup data required by add-recipe forms, including categories, allergens
/// and difficulty level labels.
class AddRecipeSetup {
  final List<AddRecipeOption> categories;
  final List<AddRecipeOption> allergens;
  final List<String> difficultyLevels;

  const AddRecipeSetup({
    required this.categories,
    required this.allergens,
    required this.difficultyLevels,
  });
}
