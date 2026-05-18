class AddRecipeIngredientModel {
  final String name;
  final String? imageUrl;
  final double amount;
  final String? unitId;
  final String? customUnitId;

  const AddRecipeIngredientModel({
    required this.name,
    this.imageUrl,
    required this.amount,
    this.unitId,
    this.customUnitId,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'image': imageUrl,
      'amount': amount,
      'unitId': unitId,
      'customUnitId': customUnitId,
    };
  }
}
