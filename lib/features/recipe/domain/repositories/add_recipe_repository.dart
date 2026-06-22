import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/add_recipe_basic_info.dart';
import '../entities/add_recipe_food_search_result.dart';
import '../entities/add_recipe_image_result.dart';
import '../entities/add_recipe_ingredient.dart';
import '../entities/add_recipe_ingredient_data.dart';
import '../entities/add_recipe_ingredient_unit.dart';
import '../entities/add_recipe_instruction.dart';
import '../entities/add_recipe_review.dart';
import '../entities/add_recipe_setup.dart';
import '../entities/add_recipe_video_result.dart';

abstract class AddRecipeRepository {
  Future<Either<Failure, AddRecipeSetup>> getSetup();

  Future<Either<Failure, List<AddRecipeIngredientUnit>>> getIngredientUnits();

  Future<Either<Failure, List<AddRecipeIngredientCategory>>>
  getIngredientCategories();

  Future<Either<Failure, List<AddRecipeFoodSearchResult>>> searchFoods(
    String query,
  );

  Future<Either<Failure, Map<String, dynamic>?>> getFoodLabelNutrients(
    int fdcId,
  );

  Future<Either<Failure, String?>> getIngredientImageUrl(String ingredientName);

  Future<Either<Failure, String>> saveBasicInfo(AddRecipeBasicInfo info);

  Future<Either<Failure, AddRecipeVideoResult>> generateRecipeFromVideo(
    String videoPath,
  );

  Future<Either<Failure, AddRecipeImageResult>> generateRecipeFromImage(
    File imageFile,
  );

  Future<Either<Failure, void>> saveIngredients({
    required String recipeId,
    required List<AddRecipeIngredient> ingredients,
  });

  Future<Either<Failure, void>> saveInstructions({
    required String recipeId,
    required bool useSections,
    required List<AddRecipeInstruction> instructions,
  });

  Future<Either<Failure, AddRecipeReview>> getReview(String recipeId);

  Future<Either<Failure, void>> finalizeRecipe(String recipeId);

  Future<Either<Failure, void>> updateVisibility({
    required String recipeId,
    required String visibility,
  });

  Future<Either<Failure, void>> deleteRecipe(String recipeId);

  Future<Either<Failure, void>> completeRecipe({
    required String recipeId,
    required String mode,
  });
}
