import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_recipe_ingredient_data.dart';
import '../repositories/add_recipe_repository.dart';

/// Loads active ingredient categories used by AI nutrient analysis and review grouping.
class GetAddRecipeIngredientCategoriesUseCase {
  final AddRecipeRepository repository;

  const GetAddRecipeIngredientCategoriesUseCase(this.repository);

  Future<Either<Failure, List<AddRecipeIngredientCategory>>> execute() {
    return repository.getIngredientCategories();
  }
}
