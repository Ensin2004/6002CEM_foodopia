import 'dart:io';

class AddRecipeInstruction {
  final int? sectionIndex;
  final String? sectionTitle;
  final int stepIndex;
  final File? stepImageFile;
  final String description;

  const AddRecipeInstruction({
    required this.sectionIndex,
    required this.sectionTitle,
    required this.stepIndex,
    this.stepImageFile,
    required this.description,
  });
}
