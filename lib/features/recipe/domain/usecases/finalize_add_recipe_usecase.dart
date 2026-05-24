import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/add_recipe_repository.dart';

class FinalizeAddRecipeUseCase {
  final AddRecipeRepository repository;

  const FinalizeAddRecipeUseCase(this.repository);

  Future<Either<Failure, void>> execute(String recipeId) {
    return repository.finalizeRecipe(recipeId);
  }
}
