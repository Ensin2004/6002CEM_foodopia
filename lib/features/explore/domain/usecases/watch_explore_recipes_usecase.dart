import '../entities/explore_recipe.dart';
import '../repositories/explore_repository.dart';

class WatchExploreRecipesUseCase {
  final ExploreRepository repository;

  const WatchExploreRecipesUseCase(this.repository);

  Stream<List<ExploreRecipe>> execute() {
    return repository.watchRecipes();
  }
}
