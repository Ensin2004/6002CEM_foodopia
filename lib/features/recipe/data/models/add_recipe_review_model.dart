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
      servings: _doubleValue(recipe['servings']) ?? 1,
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
      proteins: _formatNutrient(nutrients['protein'], suffix: 'g'),
      carbohydrates: _formatNutrient(nutrients['carbohydrates'], suffix: 'g'),
      fats: _formatNutrient(nutrients['fat'], suffix: 'g'),
      fiber: _formatNutrient(nutrients['fiber'], suffix: 'g'),
      water: _formatNutrient(nutrients['water'], suffix: 'g'),
      vitamins: _nutrientRowsFromRecipe(nutrients, _vitaminDefinitions),
      minerals: _nutrientRowsFromRecipe(nutrients, _mineralDefinitions),
    );
  }

  static List<AddRecipeReviewMicronutrient> _nutrientRowsFromRecipe(
    Map<dynamic, dynamic> nutrients,
    List<_NutrientDefinition> definitions,
  ) {
    return definitions
        .map((definition) {
          final amount = _doubleValue(nutrients[definition.key]);
          if (amount == null || amount <= 0) return null;

          final percent = definition.dailyValue <= 0
              ? null
              : (amount / definition.dailyValue * 100).round();
          return AddRecipeReviewMicronutrient(
            label: definition.label,
            amount: _formatNutrient(amount, suffix: definition.unit),
            dailyValue: percent == null ? '-' : '$percent% DV',
          );
        })
        .whereType<AddRecipeReviewMicronutrient>()
        .toList(growable: false);
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

class _NutrientDefinition {
  final String key;
  final String label;
  final String unit;
  final double dailyValue;

  const _NutrientDefinition({
    required this.key,
    required this.label,
    required this.unit,
    required this.dailyValue,
  });
}

const List<_NutrientDefinition> _vitaminDefinitions = [
  _NutrientDefinition(
    key: 'vitaminA',
    label: 'Vitamin A',
    unit: 'mcg',
    dailyValue: 900,
  ),
  _NutrientDefinition(
    key: 'vitaminC',
    label: 'Vitamin C',
    unit: 'mg',
    dailyValue: 90,
  ),
  _NutrientDefinition(
    key: 'vitaminD',
    label: 'Vitamin D',
    unit: 'mcg',
    dailyValue: 20,
  ),
  _NutrientDefinition(
    key: 'vitaminE',
    label: 'Vitamin E',
    unit: 'mg',
    dailyValue: 15,
  ),
  _NutrientDefinition(
    key: 'vitaminK',
    label: 'Vitamin K',
    unit: 'mcg',
    dailyValue: 120,
  ),
  _NutrientDefinition(
    key: 'vitaminB1',
    label: 'Vitamin B1',
    unit: 'mg',
    dailyValue: 1.2,
  ),
  _NutrientDefinition(
    key: 'vitaminB2',
    label: 'Vitamin B2',
    unit: 'mg',
    dailyValue: 1.3,
  ),
  _NutrientDefinition(
    key: 'vitaminB3',
    label: 'Vitamin B3',
    unit: 'mg',
    dailyValue: 16,
  ),
  _NutrientDefinition(
    key: 'vitaminB6',
    label: 'Vitamin B6',
    unit: 'mg',
    dailyValue: 1.7,
  ),
  _NutrientDefinition(
    key: 'vitaminB9',
    label: 'Vitamin B9 (Folate)',
    unit: 'mcg',
    dailyValue: 400,
  ),
  _NutrientDefinition(
    key: 'vitaminB12',
    label: 'Vitamin B12',
    unit: 'mcg',
    dailyValue: 2.4,
  ),
];

const List<_NutrientDefinition> _mineralDefinitions = [
  _NutrientDefinition(
    key: 'calcium',
    label: 'Calcium',
    unit: 'mg',
    dailyValue: 1300,
  ),
  _NutrientDefinition(key: 'iron', label: 'Iron', unit: 'mg', dailyValue: 18),
  _NutrientDefinition(
    key: 'magnesium',
    label: 'Magnesium',
    unit: 'mg',
    dailyValue: 420,
  ),
  _NutrientDefinition(
    key: 'phosphorus',
    label: 'Phosphorus',
    unit: 'mg',
    dailyValue: 1250,
  ),
  _NutrientDefinition(
    key: 'potassium',
    label: 'Potassium',
    unit: 'mg',
    dailyValue: 4700,
  ),
  _NutrientDefinition(
    key: 'sodium',
    label: 'Sodium',
    unit: 'mg',
    dailyValue: 2300,
  ),
  _NutrientDefinition(key: 'zinc', label: 'Zinc', unit: 'mg', dailyValue: 11),
];
