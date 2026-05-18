import 'add_recipe_option.dart';

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
