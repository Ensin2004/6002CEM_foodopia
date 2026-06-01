class AddRecipeIngredientCategory {
  final String id;
  final String name;

  const AddRecipeIngredientCategory({required this.id, required this.name});
}

class AddRecipeIngredientDataInput {
  final int index;
  final String name;
  final double amount;
  final String unit;
  final Map<String, dynamic>? usdaNutrients;

  const AddRecipeIngredientDataInput({
    required this.index,
    required this.name,
    required this.amount,
    required this.unit,
    this.usdaNutrients,
  });
}

class AddRecipeIngredientData {
  final int index;
  final String ingredientCategoryId;
  final Map<String, dynamic> nutrients;

  const AddRecipeIngredientData({
    required this.index,
    required this.ingredientCategoryId,
    required this.nutrients,
  });
}
