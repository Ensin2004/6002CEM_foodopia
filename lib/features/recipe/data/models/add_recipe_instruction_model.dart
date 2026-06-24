/// Converts one cooking step into the Firestore instruction subcollection shape.
class AddRecipeInstructionModel {
  final int? sectionIndex;
  final String? sectionTitle;
  final int stepIndex;
  final String? stepImage;
  final String description;

  const AddRecipeInstructionModel({
    required this.sectionIndex,
    required this.sectionTitle,
    required this.stepIndex,
    this.stepImage,
    required this.description,
  });

  Map<String, dynamic> toFirestore() {
    // Instruction documents preserve section data, step order, image, and description.
    return {
      'sectionIndex': sectionIndex,
      'sectionTitle': sectionTitle,
      'stepIndex': stepIndex,
      'stepImage': stepImage,
      'description': description,
    };
  }
}
