import '../entities/explore_recipe.dart';
import '../repositories/explore_repository.dart';

/// Use case for observing real-time updates to a specific recipe's details.
/// Encapsulates the business logic for streaming recipe detail changes.
/// Delegates the recipe detail watching operation to the explore repository.
class WatchExploreRecipeDetailUseCase {
  /// Repository dependency for accessing recipe detail stream operations.
  final ExploreRepository repository;

  /// Constructs the use case with the required repository instance.
  const WatchExploreRecipeDetailUseCase(this.repository);

  /// Executes the recipe detail watching operation.
  /// [recipeId] - The unique identifier of the recipe to observe.
  /// Returns a Stream that emits ExploreRecipe entities on each update.
  Stream<ExploreRecipe> execute(String recipeId) {
    /// Delegate the recipe detail watching to the repository implementation.
    return repository.watchRecipeDetail(recipeId);
  }
}