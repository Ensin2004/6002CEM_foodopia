import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/add_recipe_review.dart';
import '../../domain/usecases/delete_add_recipe_usecase.dart';
import '../../domain/usecases/finalize_add_recipe_usecase.dart';
import '../../domain/usecases/get_add_recipe_review_usecase.dart';

/// Controls recipe review loading, final save state, deletion state and errors.
class AddRecipeReviewViewModel extends ChangeNotifier {
  final GetAddRecipeReviewUseCase getReviewUseCase;
  final FinalizeAddRecipeUseCase finalizeRecipeUseCase;
  final DeleteAddRecipeUseCase deleteRecipeUseCase;

  AddRecipeReview? review;
  bool isLoading = true;
  bool isSaving = false;
  bool isDeleting = false;
  String? errorMessage;

  AddRecipeReviewViewModel({
    required this.getReviewUseCase,
    required this.finalizeRecipeUseCase,
    required this.deleteRecipeUseCase,
  });

  /// Loads the latest recipe review snapshot.
  Future<void> loadReview(String recipeId) async {
    // Review loading resets any previous error before requesting fresh data.
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await getReviewUseCase.execute(recipeId);
    if (result.isLeft()) {
      errorMessage = result.left?.message ?? 'Unable to load recipe review.';
      review = null;
    } else {
      review = result.right;
    }

    isLoading = false;
    notifyListeners();
  }

  /// Finalizes the reviewed recipe after the final save action.
  Future<bool> finalizeRecipe(String recipeId) async {
    // Final save state keeps the review button disabled until completion.
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    final result = await finalizeRecipeUseCase.execute(recipeId);
    final success = result.isRight();
    if (!success) {
      errorMessage = result.left?.message ?? 'Unable to save recipe.';
    }

    isSaving = false;
    notifyListeners();
    return success;
  }

  /// Deletes the reviewed recipe and exposes any deletion failure.
  Future<bool> deleteRecipe(String recipeId) async {
    // Delete state keeps destructive action feedback separate from final save.
    isDeleting = true;
    errorMessage = null;
    notifyListeners();

    final result = await deleteRecipeUseCase.execute(recipeId);
    final success = result.isRight();
    if (!success) {
      errorMessage = result.left?.message ?? 'Unable to delete recipe.';
    }

    isDeleting = false;
    notifyListeners();
    return success;
  }
}
