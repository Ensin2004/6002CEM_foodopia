class AddRecipeIngredientModel {
  final String name;
  final String? imageUrl;
  final double amount;
  final String? unitId;
  final String? customUnitId;
  final int? usdaId;
  final Map<String, dynamic>? nutrients;

  const AddRecipeIngredientModel({
    required this.name,
    this.imageUrl,
    required this.amount,
    this.unitId,
    this.customUnitId,
    this.usdaId,
    this.nutrients,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'image': imageUrl,
      'amount': amount,
      'unitId': unitId,
      'customUnitId': customUnitId,
      'usda_id': usdaId,
      'nutrients': nutrients,
    };
  }
}
