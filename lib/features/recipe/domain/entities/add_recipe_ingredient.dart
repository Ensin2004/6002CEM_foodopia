import 'dart:io';

class AddRecipeIngredient {
  final String name;
  final File? imageFile;
  final String? existingImageUrl;
  final double amount;
  final String unitId;
  final String customUnit;
  final int? usdaId;
  final Map<String, dynamic>? usdaNutrients;

  const AddRecipeIngredient({
    required this.name,
    this.imageFile,
    this.existingImageUrl,
    required this.amount,
    required this.unitId,
    required this.customUnit,
    this.usdaId,
    this.usdaNutrients,
  });
}
