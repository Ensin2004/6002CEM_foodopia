class AddRecipeReview {
  final String recipeId;
  final List<String> media;
  final String recipeName;
  final String description;
  final List<String> otherNames;
  final List<String> categories;
  final int preparationMinutes;
  final int difficultyLevel;
  final int servings;
  final List<String> allergens;
  final String visibility;
  final AddRecipeReviewNutrients nutrients;
  final List<AddRecipeReviewIngredient> ingredients;
  final List<AddRecipeReviewInstruction> instructions;
  final bool instructionUseSection;

  const AddRecipeReview({
    required this.recipeId,
    required this.media,
    required this.recipeName,
    required this.description,
    required this.otherNames,
    required this.categories,
    required this.preparationMinutes,
    required this.difficultyLevel,
    required this.servings,
    required this.allergens,
    required this.visibility,
    required this.nutrients,
    required this.ingredients,
    required this.instructions,
    required this.instructionUseSection,
  });
}

class AddRecipeReviewNutrients {
  final String calories;
  final String proteins;
  final String carbohydrates;
  final String fats;
  final String fiber;
  final String water;
  final List<AddRecipeReviewMicronutrient> vitamins;
  final List<AddRecipeReviewMicronutrient> minerals;

  const AddRecipeReviewNutrients({
    required this.calories,
    required this.proteins,
    required this.carbohydrates,
    required this.fats,
    this.fiber = '-',
    this.water = '-',
    this.vitamins = const [],
    this.minerals = const [],
  });
}

class AddRecipeReviewMicronutrient {
  final String label;
  final String amount;
  final String dailyValue;

  const AddRecipeReviewMicronutrient({
    required this.label,
    required this.amount,
    required this.dailyValue,
  });
}

class AddRecipeReviewIngredient {
  final String name;
  final String image;
  final String amount;
  final String unit;
  final int? usdaId;
  final Map<String, dynamic>? nutrients;
  final String? ingredientCategoryId;

  const AddRecipeReviewIngredient({
    required this.name,
    required this.image,
    required this.amount,
    required this.unit,
    this.usdaId,
    this.nutrients,
    this.ingredientCategoryId,
  });
}

class AddRecipeReviewInstruction {
  final int? sectionIndex;
  final String? sectionTitle;
  final int stepIndex;
  final String image;
  final String description;

  const AddRecipeReviewInstruction({
    required this.sectionIndex,
    required this.sectionTitle,
    required this.stepIndex,
    required this.image,
    required this.description,
  });
}
