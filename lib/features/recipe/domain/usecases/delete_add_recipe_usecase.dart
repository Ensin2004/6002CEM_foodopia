import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/add_recipe_repository.dart';

/// Deletes a creator-owned recipe and all related recipe subcollection data.
class DeleteAddRecipeUseCase {
  final AddRecipeRepository repository;

  const DeleteAddRecipeUseCase(this.repository);

  Future<Either<Failure, void>> execute(String recipeId) {
    return repository.deleteRecipe(recipeId);
  }
}
