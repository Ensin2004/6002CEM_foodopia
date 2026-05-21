import '../entities/explore_recipe.dart';
import '../repositories/explore_repository.dart';

class WatchExploreRecipeDetailUseCase {
  final ExploreRepository repository;

  const WatchExploreRecipeDetailUseCase(this.repository);

  Stream<ExploreRecipe> execute(String recipeId) {
    return repository.watchRecipeDetail(recipeId);
  }
}
