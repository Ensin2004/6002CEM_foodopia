import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/usecases/update_add_recipe_visibility_usecase.dart';

class AddRecipeVisibilityViewModel extends ChangeNotifier {
  final UpdateAddRecipeVisibilityUseCase updateVisibilityUseCase;

  String visibility;
  bool isSaving = false;
  String? errorMessage;

  AddRecipeVisibilityViewModel({
    required this.updateVisibilityUseCase,
    this.visibility = 'private',
  });

  bool get isPublic => visibility == 'public';
  bool _hasSeededVisibility = false;

  void seedVisibility(String value) {
    if (_hasSeededVisibility) return;
    _hasSeededVisibility = true;
    visibility = value == 'public' ? 'public' : 'private';
    notifyListeners();
  }

  Future<bool> updateVisibility({
    required String recipeId,
    required String value,
  }) async {
    final nextVisibility = value == 'public' ? 'public' : 'private';
    final previousVisibility = visibility;
    visibility = nextVisibility;
    isSaving = true;
    errorMessage = null;
    notifyListeners();

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
      visibility = previousVisibility;
      errorMessage = result.left?.message ?? 'Unable to update visibility.';
    }

    isSaving = false;
    notifyListeners();
    return success;
  }
}
