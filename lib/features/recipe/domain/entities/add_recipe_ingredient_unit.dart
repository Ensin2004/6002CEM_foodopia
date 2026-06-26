/// Ingredient unit option with category metadata for grouped unit selection.
class AddRecipeIngredientUnit {
  final String id;
  final String name;
  final String categoryId;
  final String categoryName;

  const AddRecipeIngredientUnit({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
  });
}
