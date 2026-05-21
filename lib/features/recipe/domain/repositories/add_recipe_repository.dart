import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_recipe_basic_info.dart';
import '../entities/add_recipe_food_search_result.dart';
import '../entities/add_recipe_ingredient.dart';
import '../entities/add_recipe_ingredient_unit.dart';
import '../entities/add_recipe_instruction.dart';
import '../entities/add_recipe_setup.dart';

abstract class AddRecipeRepository {
  Future<Either<Failure, AddRecipeSetup>> getSetup();

  Future<Either<Failure, List<AddRecipeIngredientUnit>>> getIngredientUnits();

  Future<Either<Failure, List<AddRecipeFoodSearchResult>>> searchFoods(
    String query,
  );

  Future<Either<Failure, Map<String, dynamic>?>> getFoodLabelNutrients(
    int fdcId,
  );

  Future<Either<Failure, String>> saveBasicInfo(AddRecipeBasicInfo info);

  Future<Either<Failure, void>> saveIngredients({
    required String recipeId,
    required List<AddRecipeIngredient> ingredients,
  });

  Future<Either<Failure, void>> saveInstructions({
    required String recipeId,
    required bool useSections,
    required List<AddRecipeInstruction> instructions,
  });
}
