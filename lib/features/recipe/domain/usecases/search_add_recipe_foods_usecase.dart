import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_recipe_food_search_result.dart';
import '../repositories/add_recipe_repository.dart';

class SearchAddRecipeFoodsUseCase {
  final AddRecipeRepository repository;

  const SearchAddRecipeFoodsUseCase(this.repository);

  Future<Either<Failure, List<AddRecipeFoodSearchResult>>> execute(
    String query,
  ) {
    return repository.searchFoods(query);
  }
}
