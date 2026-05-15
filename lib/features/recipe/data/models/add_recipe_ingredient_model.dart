class AddRecipeIngredientModel {
  final String name;
  final String? imageUrl;
  final double amount;
  final String unit;

  const AddRecipeIngredientModel({
    required this.name,
    this.imageUrl,
    required this.amount,
    required this.unit,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'image': imageUrl,
      'amount': amount,
      'unit': unit,
    };
  }
}
