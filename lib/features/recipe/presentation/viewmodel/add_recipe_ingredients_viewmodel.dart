import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/add_recipe_food_search_result.dart';
import '../../domain/entities/add_recipe_ingredient.dart';
import '../../domain/entities/add_recipe_ingredient_unit.dart';
import '../../domain/entities/add_recipe_review.dart';
import '../../domain/usecases/get_add_recipe_review_usecase.dart';
import '../../domain/usecases/get_add_recipe_food_nutrients_usecase.dart';
import '../../domain/usecases/get_add_recipe_ingredient_image_usecase.dart';
import '../../domain/usecases/get_add_recipe_ingredient_units_usecase.dart';
import '../../domain/usecases/save_add_recipe_ingredients_usecase.dart';
import '../../domain/usecases/search_add_recipe_foods_usecase.dart';

/// Controls ingredient form state, unit loading, existing recipe seeding,
/// ingredient saving, food search, nutrient lookup and ingredient images.
class AddRecipeIngredientsViewModel extends ChangeNotifier {
  final GetAddRecipeIngredientUnitsUseCase getIngredientUnitsUseCase;
  final SearchAddRecipeFoodsUseCase searchFoodsUseCase;
  final GetAddRecipeFoodNutrientsUseCase getFoodNutrientsUseCase;
  final GetAddRecipeIngredientImageUseCase getIngredientImageUseCase;
  final SaveAddRecipeIngredientsUseCase saveIngredientsUseCase;
  final GetAddRecipeReviewUseCase getReviewUseCase;

  AddRecipeReview? existingReview;
  List<AddRecipeIngredientUnit> units = [];
  bool isLoadingUnits = true;
  bool isSaving = false;
  String? errorMessage;

  AddRecipeIngredientsViewModel({
    required this.getIngredientUnitsUseCase,
    required this.searchFoodsUseCase,
    required this.getFoodNutrientsUseCase,
    required this.getIngredientImageUseCase,
    required this.saveIngredientsUseCase,
    required this.getReviewUseCase,
  }) {
    loadUnits();
  }

  /// Loads ingredient units for the unit picker.
  Future<void> loadUnits() async {
    // Unit loading happens before ingredient rows can display configured units.
    isLoadingUnits = true;
    errorMessage = null;
    notifyListeners();

    final result = await getIngredientUnitsUseCase.execute();
    if (result.isLeft()) {
      errorMessage = result.left?.message ?? 'Unable to load ingredient units.';
      units = [];
    } else {
      units = result.right ?? [];
    }

    isLoadingUnits = false;
    notifyListeners();
  }

  /// Loads saved review data when editing ingredient rows.
  Future<void> loadExistingRecipe(String recipeId) async {
    // Empty ids and already-loaded recipes do not need another review request.
    if (recipeId.trim().isEmpty || existingReview?.recipeId == recipeId) {
      return;
    }

    // Existing ingredient rows are sourced from the same review snapshot used on review page.
    isLoadingUnits = true;
    errorMessage = null;
    notifyListeners();

    final result = await getReviewUseCase.execute(recipeId);
    if (result.isLeft()) {
      errorMessage = result.left?.message ?? 'Unable to load ingredients.';
      existingReview = null;
    } else {
      existingReview = result.right;
    }

    isLoadingUnits = false;
    notifyListeners();
  }

  /// Saves completed ingredient rows for the current recipe draft.
  Future<bool> saveIngredients({
    required String recipeId,
    required List<AddRecipeIngredient> ingredients,
  }) async {
    // Save state blocks duplicate ingredient submissions during network work.
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    final result = await saveIngredientsUseCase.execute(
      recipeId: recipeId,
      ingredients: ingredients,
    );
    final success = result.isRight();
    if (!success) {
      errorMessage = result.left?.message ?? 'Unable to save ingredients.';
    }

    isSaving = false;
    notifyListeners();
    return success;
  }

  /// Searches USDA foods for ingredient name matching.
  Future<List<AddRecipeFoodSearchResult>> searchFoods(String query) async {
    // Search failures return no suggestions so the ingredient sheet stays usable.
    final result = await searchFoodsUseCase.execute(query);
    if (result.isLeft()) return [];
    return result.right ?? [];
  }

  /// Loads nutrients for the selected USDA food id.
  Future<Map<String, dynamic>?> getFoodNutrients(int fdcId) async {
    // Nutrient lookup enriches a selected USDA ingredient row.
    final result = await getFoodNutrientsUseCase.execute(fdcId);
    if (result.isLeft()) return null;
    return result.right;
  }

  /// Loads an image URL for a named ingredient.
  Future<String?> getIngredientImageUrl(String ingredientName) async {
    // Image lookup failures keep the ingredient row without a remote preview.
    final result = await getIngredientImageUseCase.execute(ingredientName);
    if (result.isLeft()) return null;
    return result.right;
  }
}
