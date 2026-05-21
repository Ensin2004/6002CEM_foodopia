import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/explore_recipe.dart';
import '../repositories/explore_repository.dart';

class GetExploreRecipeDetailUseCase {
  final ExploreRepository repository;

  const GetExploreRecipeDetailUseCase(this.repository);

  Future<Either<Failure, ExploreRecipe>> execute(String recipeId) {
    return repository.getRecipeDetail(recipeId);
  }
}
