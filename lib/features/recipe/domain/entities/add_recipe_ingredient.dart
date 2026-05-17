import 'dart:io';

class AddRecipeIngredient {
  final String name;
  final File? imageFile;
  final double amount;
  final String unit;

  const AddRecipeIngredient({
    required this.name,
    this.imageFile,
    required this.amount,
    required this.unit,
  });
}
