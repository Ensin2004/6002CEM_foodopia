import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/explore_recipe.dart';
import '../repositories/explore_repository.dart';

class GetExploreRecipesUseCase {
  final ExploreRepository repository;

  const GetExploreRecipesUseCase(this.repository);

  Future<Either<Failure, List<ExploreRecipe>>> execute() {
    return repository.getRecipes();
  }
}
