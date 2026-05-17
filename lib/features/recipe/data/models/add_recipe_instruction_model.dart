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
    return {
      'sectionIndex': sectionIndex,
      'sectionTitle': sectionTitle,
      'stepIndex': stepIndex,
      'stepImage': stepImage,
      'description': description,
    };
  }
}
