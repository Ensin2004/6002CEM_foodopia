import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/add_recipe_basic_info.dart';
import '../../domain/entities/add_recipe_food_search_result.dart';
import '../../domain/entities/add_recipe_ingredient.dart';
import '../../domain/entities/add_recipe_ingredient_unit.dart';
import '../../domain/entities/add_recipe_instruction.dart';
import '../../domain/entities/add_recipe_review.dart';
import '../../domain/entities/add_recipe_setup.dart';
import '../../domain/repositories/add_recipe_repository.dart';
import '../datasources/add_recipe_remote_datasource.dart';

class AddRecipeRepositoryImpl implements AddRecipeRepository {
  final AddRecipeRemoteDataSource remoteDataSource;

  const AddRecipeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AddRecipeSetup>> getSetup() async {
    try {
      final setup = await remoteDataSource.getSetup();
      return Right(setup);
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load recipe categories.'));
    }
  }

  @override
  Future<Either<Failure, List<AddRecipeIngredientUnit>>>
  getIngredientUnits() async {
    try {
      final units = await remoteDataSource.getIngredientUnits();
      return Right(units);
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load ingredient units.'));
    }
  }

  @override
  Future<Either<Failure, List<AddRecipeFoodSearchResult>>> searchFoods(
    String query,
  ) async {
    try {
      final foods = await remoteDataSource.searchFoods(query);
      return Right(foods);
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to search USDA foods.'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>?>> getFoodLabelNutrients(
    int fdcId,
  ) async {
    try {
      final nutrients = await remoteDataSource.getFoodLabelNutrients(fdcId);
      return Right(nutrients);
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load USDA nutrients.'));
    }
  }

  @override
  Future<Either<Failure, String>> saveBasicInfo(AddRecipeBasicInfo info) async {
    if (info.mediaFiles.isEmpty && info.existingMediaUrls.isEmpty) {
      return Left(ValidationFailure(message: 'Please upload a recipe image.'));
    }
    if (info.recipeName.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Please enter a recipe name.'));
    }
    if (info.description.trim().isEmpty) {
      return Left(
        ValidationFailure(message: 'Please enter a recipe description.'),
      );
    }
    if (info.categoryIds.isEmpty && info.customCategories.isEmpty) {
      return Left(ValidationFailure(message: 'Please select a category.'));
    }
    if (info.preparationMinutes <= 0) {
      return Left(
        ValidationFailure(message: 'Preparation time must be more than 0.'),
      );
    }
    if (info.difficultyLevel < 1 || info.difficultyLevel > 5) {
      return Left(
        ValidationFailure(
          message: 'Please select a difficulty level from 1 to 5.',
        ),
      );
    }
    if (info.servings <= 0) {
      return Left(ValidationFailure(message: 'Servings must be more than 0.'));
    }

    try {
      final recipeId = await remoteDataSource.saveBasicInfo(info);
      return Right(recipeId);
    } catch (error) {
      return Left(
        ServerFailure(message: 'Unable to save recipe basic info: $error'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> saveIngredients({
    required String recipeId,
    required List<AddRecipeIngredient> ingredients,
  }) async {
    if (recipeId.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Recipe id is missing.'));
    }
    if (ingredients.isEmpty) {
      return Left(
        ValidationFailure(message: 'Please add at least one ingredient.'),
      );
    }

    for (final ingredient in ingredients) {
      if (ingredient.name.trim().isEmpty) {
        return Left(ValidationFailure(message: 'Ingredient name is required.'));
      }
      if (ingredient.amount <= 0) {
        return Left(
          ValidationFailure(message: 'Ingredient amount must be more than 0.'),
        );
      }
      if (ingredient.unitId.trim().isEmpty &&
          ingredient.customUnit.trim().isEmpty) {
        return Left(ValidationFailure(message: 'Ingredient unit is required.'));
      }
    }

    try {
      await remoteDataSource.saveIngredients(
        recipeId: recipeId,
        ingredients: ingredients,
      );
      return const Right(null);
    } catch (error) {
      return Left(ServerFailure(message: 'Unable to save ingredients: $error'));
    }
  }

  @override
  Future<Either<Failure, void>> saveInstructions({
    required String recipeId,
    required bool useSections,
    required List<AddRecipeInstruction> instructions,
  }) async {
    if (recipeId.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Recipe id is missing.'));
    }
    if (instructions.isEmpty) {
      return Left(
        ValidationFailure(message: 'Please add at least one instruction.'),
      );
    }

    for (final instruction in instructions) {
      if (instruction.description.trim().isEmpty) {
        return Left(
          ValidationFailure(message: 'Instruction description is required.'),
        );
      }
      if (instruction.stepIndex < 1) {
        return Left(ValidationFailure(message: 'Instruction step is invalid.'));
      }
      if (useSections &&
          (instruction.sectionIndex == null ||
              instruction.sectionIndex! < 1 ||
              instruction.sectionTitle == null ||
              instruction.sectionTitle!.trim().isEmpty)) {
        return Left(
          ValidationFailure(message: 'Instruction section is required.'),
        );
      }
    }

    try {
      await remoteDataSource.saveInstructions(
        recipeId: recipeId,
        useSections: useSections,
        instructions: instructions,
      );
      return const Right(null);
    } catch (error) {
      return Left(
        ServerFailure(message: 'Unable to save instructions: $error'),
      );
    }
  }

  @override
  Future<Either<Failure, AddRecipeReview>> getReview(String recipeId) async {
    if (recipeId.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Recipe id is missing.'));
    }

    try {
      final review = await remoteDataSource.getReview(recipeId);
      return Right(review);
    } catch (error) {
      return Left(
        ServerFailure(message: 'Unable to load recipe review: $error'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> updateVisibility({
    required String recipeId,
    required String visibility,
  }) async {
    if (recipeId.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Recipe id is missing.'));
    }
    if (visibility != 'public' && visibility != 'private') {
      return Left(ValidationFailure(message: 'Recipe visibility is invalid.'));
    }

    try {
      await remoteDataSource.updateVisibility(
        recipeId: recipeId,
        visibility: visibility,
      );
      return const Right(null);
    } catch (error) {
      return Left(
        ServerFailure(message: 'Unable to update recipe visibility: $error'),
      );
    }
  }
}
