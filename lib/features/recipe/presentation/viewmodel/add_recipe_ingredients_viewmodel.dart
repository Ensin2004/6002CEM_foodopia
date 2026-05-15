import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/add_recipe_ingredient.dart';
import '../../domain/usecases/get_add_recipe_ingredient_units_usecase.dart';
import '../../domain/usecases/save_add_recipe_ingredients_usecase.dart';

class AddRecipeIngredientsViewModel extends ChangeNotifier {
  final GetAddRecipeIngredientUnitsUseCase getIngredientUnitsUseCase;
  final SaveAddRecipeIngredientsUseCase saveIngredientsUseCase;

  List<String> units = [];
  bool isLoadingUnits = true;
  bool isSaving = false;
  String? errorMessage;

  AddRecipeIngredientsViewModel({
    required this.getIngredientUnitsUseCase,
    required this.saveIngredientsUseCase,
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
}
