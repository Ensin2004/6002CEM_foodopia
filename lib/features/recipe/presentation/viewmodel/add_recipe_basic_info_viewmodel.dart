import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/add_recipe_basic_info.dart';
import '../../domain/entities/add_recipe_food_search_result.dart';
import '../../domain/entities/add_recipe_review.dart';
import '../../domain/entities/add_recipe_setup.dart';
import '../../domain/usecases/get_add_recipe_review_usecase.dart';
import '../../domain/usecases/get_add_recipe_setup_usecase.dart';
import '../../domain/usecases/save_add_recipe_basic_info_usecase.dart';
import '../../domain/usecases/search_add_recipe_foods_usecase.dart';

/// Controls basic recipe information state, setup loading, existing recipe seeding,
/// difficulty selection, saving and food search for allergen suggestions.
class AddRecipeBasicInfoViewModel extends ChangeNotifier {
  final GetAddRecipeSetupUseCase getSetupUseCase;
  final SearchAddRecipeFoodsUseCase searchFoodsUseCase;
  final SaveAddRecipeBasicInfoUseCase saveBasicInfoUseCase;
  final GetAddRecipeReviewUseCase getReviewUseCase;

  AddRecipeSetup? setup;
  AddRecipeReview? existingReview;
  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;
  String? savedRecipeId;
  int difficultyLevel = 0;

  AddRecipeBasicInfoViewModel({
    required this.getSetupUseCase,
    required this.searchFoodsUseCase,
    required this.saveBasicInfoUseCase,
    required this.getReviewUseCase,
  }) {
    loadSetup();
  }

  /// Loads setup data needed by the basic information form.
  Future<void> loadSetup() async {
    // Setup loading starts immediately so category and allergen choices can render.
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await getSetupUseCase.execute();
    if (result.isLeft()) {
      errorMessage = result.left?.message ?? 'Unable to load recipe setup.';
    } else {
      setup = result.right;
      difficultyLevel = existingReview?.difficultyLevel ?? 0;
    }

    isLoading = false;
    notifyListeners();
  }

  /// Loads saved review data when editing an existing recipe.
  Future<void> loadExistingRecipe(String recipeId) async {
    // Empty ids and already-loaded recipes do not need another review request.
    if (recipeId.trim().isEmpty || existingReview?.recipeId == recipeId) {
      return;
    }

    // Existing recipe data comes from the review snapshot used by edit screens.
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await getReviewUseCase.execute(recipeId);
    if (result.isLeft()) {
      errorMessage = result.left?.message ?? 'Unable to load recipe details.';
      existingReview = null;
    } else {
      existingReview = result.right;
      difficultyLevel = existingReview?.difficultyLevel ?? difficultyLevel;
    }

    isLoading = false;
    notifyListeners();
  }

  /// Updates the selected difficulty level and refreshes the form state.
  void selectDifficulty(int value) {
    // Difficulty stays inside the supported one-to-five level range.
    difficultyLevel = value < 1
        ? 1
        : value > 5
        ? 5
        : value;
    errorMessage = null;
    notifyListeners();
  }

  /// Saves basic recipe information and stores the saved recipe id.
  Future<bool> saveBasicInfo(AddRecipeBasicInfo info) async {
    // Save state disables repeat submissions until the use case finishes.
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    final result = await saveBasicInfoUseCase.execute(info);
    final success = result.isRight();
    if (!success) {
      errorMessage = result.left?.message ?? 'Unable to save basic info.';
      savedRecipeId = null;
    } else {
      savedRecipeId = result.right;
    }

    // Successful saves expose the recipe id for navigation to the next step.
    isSaving = false;
    notifyListeners();
    return success;
  }

  /// Searches foods for option suggestions in the basic information form.
  Future<List<AddRecipeFoodSearchResult>> searchFoods(String query) async {
    // Food search failures return an empty suggestion list for the picker.
    final result = await searchFoodsUseCase.execute(query);
    if (result.isLeft()) return [];
    return result.right ?? [];
  }
}
