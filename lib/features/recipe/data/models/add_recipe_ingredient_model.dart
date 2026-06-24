/// Converts one ingredient entry into the Firestore ingredient subcollection shape.
class AddRecipeIngredientModel {
  final String name;
  final String? imageUrl;
  final double amount;
  final String? unitId;
  final String? customUnitId;
  final int? usdaId;
  final Map<String, dynamic>? nutrients;
  final String? ingredientCategoryId;

  const AddRecipeIngredientModel({
    required this.name,
    this.imageUrl,
    required this.amount,
    this.unitId,
    this.customUnitId,
    this.usdaId,
    this.nutrients,
    this.ingredientCategoryId,
  });

  Map<String, dynamic> toFirestore() {
    // Ingredient documents store both configured ids and custom references when needed.
    return {
      'name': name,
      'image': imageUrl,
      'amount': amount,
      'unitId': unitId,
      'customUnitId': customUnitId,
      'usda_id': usdaId,
      'nutrients': nutrients,
      'ingredient_categories_id': ingredientCategoryId,
    };
  }
}
