import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/add_recipe_food_search_result.dart';
import '../../domain/entities/add_recipe_ingredient.dart';
import '../../domain/entities/add_recipe_ingredient_unit.dart';
import '../../domain/entities/add_recipe_review.dart';
import '../../domain/usecases/get_add_recipe_review_usecase.dart';
import '../../domain/usecases/get_add_recipe_food_nutrients_usecase.dart';
import '../../domain/usecases/get_add_recipe_ingredient_units_usecase.dart';
import '../../domain/usecases/save_add_recipe_ingredients_usecase.dart';
import '../../domain/usecases/search_add_recipe_foods_usecase.dart';

class AddRecipeIngredientsViewModel extends ChangeNotifier {
  final GetAddRecipeIngredientUnitsUseCase getIngredientUnitsUseCase;
  final SearchAddRecipeFoodsUseCase searchFoodsUseCase;
  final GetAddRecipeFoodNutrientsUseCase getFoodNutrientsUseCase;
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
    required this.saveIngredientsUseCase,
    required this.getReviewUseCase,
  }) {
    loadUnits();
  }

  Future<void> loadUnits() async {
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

  Future<void> loadExistingRecipe(String recipeId) async {
    if (recipeId.trim().isEmpty || existingReview?.recipeId == recipeId) {
      return;
    }

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

  Future<bool> saveIngredients({
    required String recipeId,
    required List<AddRecipeIngredient> ingredients,
  }) async {
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

  Future<List<AddRecipeFoodSearchResult>> searchFoods(String query) async {
    final result = await searchFoodsUseCase.execute(query);
    if (result.isLeft()) return [];
    return result.right ?? [];
  }

  Future<Map<String, dynamic>?> getFoodNutrients(int fdcId) async {
    final result = await getFoodNutrientsUseCase.execute(fdcId);
    if (result.isLeft()) return null;
    return result.right;
  }
}
