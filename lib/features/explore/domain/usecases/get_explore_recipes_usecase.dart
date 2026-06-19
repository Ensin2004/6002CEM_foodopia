import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/explore_recipe.dart';
import '../repositories/explore_repository.dart';

/// Use case for retrieving all available recipes in the explore section.
/// Encapsulates the business logic for fetching a list of recipes.
/// Delegates the recipe collection retrieval operation to the explore repository.
class GetExploreRecipesUseCase {
  /// Repository dependency for accessing recipe list data operations.
  final ExploreRepository repository;

  /// Constructs the use case with the required repository instance.
  const GetExploreRecipesUseCase(this.repository);

  /// Executes the recipe list retrieval operation.
  /// Returns either a Failure or a list of ExploreRecipe entities.
  Future<Either<Failure, List<ExploreRecipe>>> execute() {
    /// Delegate the recipe list retrieval to the repository implementation.
    return repository.getRecipes();
  }
}