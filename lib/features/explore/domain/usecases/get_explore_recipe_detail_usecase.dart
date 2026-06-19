import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/explore_recipe.dart';
import '../repositories/explore_repository.dart';

/// Use case for retrieving detailed information about a specific recipe.
/// Encapsulates the business logic for fetching single recipe details.
/// Delegates the recipe detail retrieval operation to the explore repository.
class GetExploreRecipeDetailUseCase {
  /// Repository dependency for accessing recipe detail data operations.
  final ExploreRepository repository;

  /// Constructs the use case with the required repository instance.
  const GetExploreRecipeDetailUseCase(this.repository);

  /// Executes the recipe detail retrieval operation.
  /// [recipeId] - The unique identifier of the recipe to fetch.
  /// Returns either a Failure or the requested ExploreRecipe entity.
  Future<Either<Failure, ExploreRecipe>> execute(String recipeId) {
    /// Delegate the recipe detail retrieval to the repository implementation.
    return repository.getRecipeDetail(recipeId);
  }
}