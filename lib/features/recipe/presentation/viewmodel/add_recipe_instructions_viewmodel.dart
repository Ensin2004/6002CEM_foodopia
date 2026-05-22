import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/add_recipe_instruction.dart';
import '../../domain/entities/add_recipe_review.dart';
import '../../domain/usecases/get_add_recipe_review_usecase.dart';
import '../../domain/usecases/save_add_recipe_instructions_usecase.dart';

class AddRecipeInstructionsViewModel extends ChangeNotifier {
  final SaveAddRecipeInstructionsUseCase saveInstructionsUseCase;
  final GetAddRecipeReviewUseCase getReviewUseCase;

  AddRecipeReview? existingReview;
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  AddRecipeInstructionsViewModel({
    required this.saveInstructionsUseCase,
    required this.getReviewUseCase,
  });

  Future<void> loadExistingRecipe(String recipeId) async {
    if (recipeId.trim().isEmpty || existingReview?.recipeId == recipeId) {
      return;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await getReviewUseCase.execute(recipeId);
    if (result.isLeft()) {
      errorMessage = result.left?.message ?? 'Unable to load instructions.';
      existingReview = null;
    } else {
      existingReview = result.right;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> saveInstructions({
    required String recipeId,
    required bool useSections,
    required List<AddRecipeInstruction> instructions,
  }) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    final result = await saveInstructionsUseCase.execute(
      recipeId: recipeId,
      useSections: useSections,
      instructions: instructions,
    );
    final success = result.isRight();
    if (!success) {
      errorMessage = result.left?.message ?? 'Unable to save instructions.';
    }

    isSaving = false;
    notifyListeners();
    return success;
  }
}
