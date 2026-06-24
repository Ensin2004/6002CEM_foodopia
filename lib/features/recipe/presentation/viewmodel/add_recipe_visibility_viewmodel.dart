import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/usecases/update_add_recipe_visibility_usecase.dart';

/// Controls recipe visibility state, one-time visibility seeding, saving
/// and visibility update errors for add-recipe screens.
class AddRecipeVisibilityViewModel extends ChangeNotifier {
  final UpdateAddRecipeVisibilityUseCase updateVisibilityUseCase;

  String visibility;
  bool isSaving = false;
  String? errorMessage;

  AddRecipeVisibilityViewModel({
    required this.updateVisibilityUseCase,
    this.visibility = 'private',
  });

  /// Indicates whether the current recipe visibility is public.
  bool get isPublic => visibility == 'public';
  bool _hasSeededVisibility = false;

  /// Applies stored visibility once when an existing recipe loads.
  void seedVisibility(String value) {
    // One-time seeding avoids overwriting user changes after screen rebuilds.
    if (_hasSeededVisibility) return;
    _hasSeededVisibility = true;
    final nextVisibility = value == 'public' ? 'public' : 'private';
    if (visibility == nextVisibility) return;
    visibility = nextVisibility;
    notifyListeners();
  }

  /// Saves the next visibility value and refreshes local state after success.
  Future<bool> updateVisibility({
    required String recipeId,
    required String value,
  }) async {
    // Visibility saves normalize every value to public or private.
    final nextVisibility = value == 'public' ? 'public' : 'private';
    final previousVisibility = visibility;
    visibility = nextVisibility;
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    // Unsaved drafts can update local visibility without a remote document.
    if (recipeId.trim().isEmpty) {
      isSaving = false;
      notifyListeners();
      return true;
    }

    final result = await updateVisibilityUseCase.execute(
      recipeId: recipeId,
      visibility: nextVisibility,
    );
    final success = result.isRight();
    if (!success) {
      // Failed remote saves restore the previous visibility state.
      visibility = previousVisibility;
      errorMessage = result.left?.message ?? 'Unable to update visibility.';
    }

    isSaving = false;
    notifyListeners();
    return success;
  }
}
