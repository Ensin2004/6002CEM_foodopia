import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/add_recipe_repository.dart';

/// Completes a recipe draft by storing the creation mode and finalizing the recipe.
class CompleteAddRecipeUseCase {
  final AddRecipeRepository repository;

  const CompleteAddRecipeUseCase(this.repository);

  Future<Either<Failure, void>> execute({
    required String recipeId,
    required String mode,
  }) {
    return repository.completeRecipe(recipeId: recipeId, mode: mode);
  }
}
