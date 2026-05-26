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
      nutrients: _nutrientsFromRecipe(recipe['totalNutrients']),
      ingredients: ingredients,
      instructions: instructions,
      instructionUseSection: recipe['instructionUseSection'] == true,
    );
  }

  static AddRecipeReviewNutrients _nutrientsFromRecipe(dynamic value) {
    final nutrients = value is Map ? value : const {};
    return AddRecipeReviewNutrients(
      calories: _formatNutrient(nutrients['calories'], suffix: 'kcal'),
      carbohydrates: _formatNutrient(nutrients['carbohydrates'], suffix: 'g'),
      proteins: _formatNutrient(nutrients['protein'], suffix: 'g'),
      fats: _formatNutrient(nutrients['fat'], suffix: 'g'),
    );
  }

  static String _formatNutrient(dynamic value, {required String suffix}) {
    final number = _doubleValue(value);
    if (number == null) return '-';
    final rounded = number.roundToDouble();
    final text = (number - rounded).abs() < 0.05
        ? rounded.toInt().toString()
        : number.toStringAsFixed(1);
    return '$text $suffix';
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

  static double? _doubleValue(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is Map) return _doubleValue(value['value'] ?? value['amount']);
    return double.tryParse(value?.toString() ?? '');
  }
}
