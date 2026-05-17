import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/explore_recipe.dart';

abstract class ExploreRepository {
  Future<Either<Failure, List<ExploreRecipe>>> getRecipes();

  Future<Either<Failure, ExploreRecipe>> getRecipeDetail(String recipeId);
}
