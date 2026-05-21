import '../../domain/entities/add_recipe_review.dart';

class AddRecipeReviewModel extends AddRecipeReview {
  const AddRecipeReviewModel({
    required super.recipeId,
    required super.media,
    required super.recipeName,
    required super.description,
    required super.otherNames,
    required super.categories,
    required super.preparationMinutes,
    required super.difficultyLevel,
    required super.servings,
    required super.allergens,
    required super.visibility,
    required super.nutrients,
    required super.ingredients,
    required super.instructions,
    required super.instructionUseSection,
  });

  factory AddRecipeReviewModel.fromParts({
    required String recipeId,
    required Map<String, dynamic> recipe,
    required List<String> categories,
    required List<String> allergens,
    required List<AddRecipeReviewIngredient> ingredients,
    required List<AddRecipeReviewInstruction> instructions,
  }) {
    return AddRecipeReviewModel(
      recipeId: recipeId,
      media: _stringList(recipe['media']),
      recipeName: recipe['name']?.toString() ?? '',
      description: recipe['description']?.toString() ?? '',
      otherNames: _stringList(recipe['otherNames']),
      categories: categories,
      preparationMinutes: _intValue(recipe['preparationTime']),
      difficultyLevel: _intValue(recipe['difficultyLevel']),
      servings: _intValue(recipe['servings']),
      allergens: allergens,
      visibility: recipe['visibility'] == 'public' ? 'public' : 'private',
      nutrients: const AddRecipeReviewNutrients(
        calories: '500 kcal',
        carbohydrates: '62 g',
        proteins: '18 g',
        fats: '24 g',
      ),
      ingredients: ingredients,
      instructions: instructions,
      instructionUseSection: recipe['instructionUseSection'] == true,
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }

  static int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
