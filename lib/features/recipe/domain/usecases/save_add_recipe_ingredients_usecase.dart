import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_recipe_ingredient.dart';
import '../repositories/add_recipe_repository.dart';

/// Validates and saves ingredient rows for a recipe draft.
class SaveAddRecipeIngredientsUseCase {
  final AddRecipeRepository repository;

  const SaveAddRecipeIngredientsUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String recipeId,
    required List<AddRecipeIngredient> ingredients,
  }) {
    return repository.saveIngredients(
      recipeId: recipeId,
      ingredients: ingredients,
    );
  }
}
