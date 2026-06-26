import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/add_recipe_instruction.dart';
import '../../domain/entities/add_recipe_review.dart';
import '../../domain/usecases/get_add_recipe_review_usecase.dart';
import '../../domain/usecases/save_add_recipe_instructions_usecase.dart';

/// Controls instruction form state, existing recipe seeding, saving,
/// and validation feedback for flat or sectioned instructions.
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

  /// Loads saved review data when editing cooking instructions.
  Future<void> loadExistingRecipe(String recipeId) async {
    // Empty ids and already-loaded recipes do not need another review request.
    if (recipeId.trim().isEmpty || existingReview?.recipeId == recipeId) {
      return;
    }

    // Existing instructions are read from review data so edit order matches review order.
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

  /// Saves instruction steps and section mode for the current recipe draft.
  Future<bool> saveInstructions({
    required String recipeId,
    required bool useSections,
    required List<AddRecipeInstruction> instructions,
  }) async {
    // Save state prevents duplicate instruction writes while validation runs.
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
