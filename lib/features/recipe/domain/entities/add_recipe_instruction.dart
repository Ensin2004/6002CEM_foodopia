import 'dart:io';

/// Editable cooking instruction step with optional section data and step image.
class AddRecipeInstruction {
  final int? sectionIndex;
  final String? sectionTitle;
  final int stepIndex;
  final File? stepImageFile;
  final String? existingStepImageUrl;
  final String description;

  const AddRecipeInstruction({
    required this.sectionIndex,
    required this.sectionTitle,
    required this.stepIndex,
    this.stepImageFile,
    this.existingStepImageUrl,
    required this.description,
  });
}
