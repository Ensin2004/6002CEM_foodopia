import '../entities/explore_recipe.dart';
import '../repositories/explore_repository.dart';

/// Use case for observing real-time updates to the list of explore recipes.
/// Encapsulates the business logic for streaming recipe collection changes.
/// Delegates the recipe list watching operation to the explore repository.
class WatchExploreRecipesUseCase {
  /// Repository dependency for accessing recipe list stream operations.
  final ExploreRepository repository;

  /// Constructs the use case with the required repository instance.
  const WatchExploreRecipesUseCase(this.repository);

  /// Executes the recipe list watching operation.
  /// Returns a Stream that emits lists of ExploreRecipe entities on each update.
  Stream<List<ExploreRecipe>> execute() {
    /// Delegate the recipe list watching to the repository implementation.
    return repository.watchRecipes();
  }
}