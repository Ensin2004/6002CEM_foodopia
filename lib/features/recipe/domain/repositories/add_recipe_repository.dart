import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_recipe_basic_info.dart';
import '../entities/add_recipe_ingredient.dart';
import '../entities/add_recipe_setup.dart';

abstract class AddRecipeRepository {
  Future<Either<Failure, AddRecipeSetup>> getSetup();

  Future<Either<Failure, List<String>>> getIngredientUnits();

  Future<Either<Failure, String>> saveBasicInfo(AddRecipeBasicInfo info);

  Future<Either<Failure, void>> saveIngredients({
    required String recipeId,
    required List<AddRecipeIngredient> ingredients,
  });
}
