import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/add_recipe_basic_info.dart';
import '../../domain/entities/add_recipe_food_search_result.dart';
import '../../domain/entities/add_recipe_image_result.dart';
import '../../domain/entities/add_recipe_ingredient.dart';
import '../../domain/entities/add_recipe_ingredient_data.dart';
import '../../domain/entities/add_recipe_ingredient_unit.dart';
import '../../domain/entities/add_recipe_instruction.dart';
import '../../domain/entities/add_recipe_review.dart';
import '../../domain/entities/add_recipe_setup.dart';
import '../../domain/entities/add_recipe_video_result.dart';
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
  Future<Either<Failure, List<AddRecipeIngredientCategory>>>
  getIngredientCategories() async {
    try {
      final categories = await remoteDataSource.getActiveIngredientCategories();
      return Right(categories);
    } catch (_) {
      return Left(
        ServerFailure(message: 'Unable to load ingredient categories.'),
      );
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
  Future<Either<Failure, String?>> getIngredientImageUrl(
    String ingredientName,
  ) async {
    try {
      final imageUrl = await remoteDataSource.getIngredientImageUrl(
        ingredientName,
      );
      return Right(imageUrl);
    } catch (_) {
      return Left(
        ServerFailure(message: 'Unable to load Unsplash ingredient image.'),
      );
    }
  }

  @override
  Future<Either<Failure, String>> saveBasicInfo(AddRecipeBasicInfo info) async {
    if (info.mediaFiles.isEmpty &&
        info.existingMediaUrls.isEmpty &&
        !info.isAiGenerated) {
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
    final localFailure = _validateBasicInfoLocally(info);
    if (localFailure != null) return Left(localFailure);

    try {
      await remoteDataSource.validateBasicInfo(info);
      final recipeId = await remoteDataSource.saveBasicInfo(info);
      return Right(recipeId);
    } on RecipeContentValidationException catch (error) {
      return Left(ValidationFailure(message: error.message));
    } catch (error) {
      return Left(
        ServerFailure(message: 'Unable to save recipe basic info: $error'),
      );
    }
  }

  @override
  Future<Either<Failure, AddRecipeVideoResult>> generateRecipeFromVideo(
    String videoPath,
  ) async {
    if (videoPath.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Please select a video.'));
    }

    try {
      final result = await remoteDataSource.generateRecipeFromVideo(videoPath);
      if (result.ingredients.isEmpty || result.instructions.isEmpty) {
        return Left(
          ServerFailure(
            message: 'Unable to detect enough recipe details from the video.',
          ),
        );
      }
      return Right(result);
    } catch (error) {
      return Left(
        ServerFailure(message: 'Unable to generate recipe from video: $error'),
      );
    }
  }

  @override
  Future<Either<Failure, AddRecipeImageResult>> generateRecipeFromImage(
    File imageFile,
  ) async {
    if (imageFile.path.trim().isEmpty || !await imageFile.exists()) {
      return Left(ValidationFailure(message: 'Please select an image.'));
    }

    try {
      final result = await remoteDataSource.generateRecipeFromImage(
        imageFile,
      );
      if (result.recipeName.trim().isEmpty ||
          result.description.trim().isEmpty) {
        return Left(
          ServerFailure(
            message: 'Unable to generate recipe details from this image.',
          ),
        );
      }
      if (result.ingredients.isEmpty) {
        return Left(
          ServerFailure(
            message: 'Unable to detect ingredients from this image.',
          ),
        );
      }
      if (result.instructions.isEmpty) {
        return Left(
          ServerFailure(
            message: 'Unable to generate instructions from this image.',
          ),
        );
      }
      return Right(result);
    } on RecipeContentValidationException catch (error) {
      return Left(ValidationFailure(message: error.message));
    } catch (error) {
      return Left(
        ServerFailure(message: 'Unable to generate recipe from image: $error'),
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
    final localFailure = _validateIngredientsLocally(ingredients);
    if (localFailure != null) return Left(localFailure);

    try {
      await remoteDataSource.validateIngredients(ingredients);
      await remoteDataSource.saveIngredients(
        recipeId: recipeId,
        ingredients: ingredients,
      );
      return const Right(null);
    } on RecipeContentValidationException catch (error) {
      return Left(ValidationFailure(message: error.message));
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
    final localFailure = _validateInstructionsLocally(instructions);
    if (localFailure != null) return Left(localFailure);

    try {
      await remoteDataSource.validateInstructions(
        useSections: useSections,
        instructions: instructions,
      );
      await remoteDataSource.saveInstructions(
        recipeId: recipeId,
        useSections: useSections,
        instructions: instructions,
      );
      return const Right(null);
    } on RecipeContentValidationException catch (error) {
      return Left(ValidationFailure(message: error.message));
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
  Future<Either<Failure, void>> finalizeRecipe(String recipeId) async {
    if (recipeId.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Recipe id is missing.'));
    }

    try {
      await remoteDataSource.validateReview(recipeId);
      await remoteDataSource.finalizeRecipe(recipeId);
      return const Right(null);
    } on RecipeContentValidationException catch (error) {
      return Left(ValidationFailure(message: error.message));
    } catch (error) {
      return Left(ServerFailure(message: 'Unable to save recipe: $error'));
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

  @override
  Future<Either<Failure, void>> deleteRecipe(String recipeId) async {
    if (recipeId.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Recipe id is missing.'));
    }

    try {
      await remoteDataSource.deleteRecipe(recipeId);
      return const Right(null);
    } catch (error) {
      return Left(ServerFailure(message: 'Unable to delete recipe: $error'));
    }
  }

  @override
  Future<Either<Failure, void>> completeRecipe({
    required String recipeId,
    required String mode,
  }) async {
    if (recipeId.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Recipe id is missing.'));
    }

    try {
      await remoteDataSource.validateReview(recipeId);
      await remoteDataSource.completeRecipe(recipeId: recipeId, mode: mode);
      return const Right(null);
    } on RecipeContentValidationException catch (error) {
      return Left(ValidationFailure(message: error.message));
    } catch (error) {
      return Left(ServerFailure(message: 'Unable to complete recipe: $error'));
    }
  }

  Failure? _validateBasicInfoLocally(AddRecipeBasicInfo info) {
    final nameFailure = _validateHumanText(
      info.recipeName,
      fieldName: 'Recipe name',
      maxLength: 120,
    );
    if (nameFailure != null) return nameFailure;

    final descriptionFailure = _validateHumanText(
      info.description,
      fieldName: 'Recipe description',
      maxLength: 1000,
    );
    if (descriptionFailure != null) return descriptionFailure;

    if (info.preparationMinutes > 1440) {
      return ValidationFailure(
        message: 'Preparation time cannot be more than 24 hours.',
      );
    }
    if (info.servings > 100) {
      return ValidationFailure(message: 'Servings cannot be more than 100.');
    }

    for (final value in [
      ...info.otherNames,
      ...info.customCategories,
      ...info.customAllergens,
    ]) {
      final failure = _validateHumanText(
        value,
        fieldName: 'Recipe content',
        maxLength: 120,
        allowEmpty: true,
      );
      if (failure != null) return failure;
    }

    return null;
  }

  Failure? _validateIngredientsLocally(List<AddRecipeIngredient> ingredients) {
    if (ingredients.length > 100) {
      return ValidationFailure(message: 'Please keep ingredients under 100.');
    }

    for (final ingredient in ingredients) {
      final nameFailure = _validateHumanText(
        ingredient.name,
        fieldName: 'Ingredient name',
        maxLength: 120,
      );
      if (nameFailure != null) return nameFailure;

      if (ingredient.amount > 10000) {
        return ValidationFailure(
          message: 'Ingredient amounts cannot be extreme.',
        );
      }

      final unit = ingredient.customUnit.trim();
      if (unit.isNotEmpty) {
        final unitFailure = _validateHumanText(
          unit,
          fieldName: 'Ingredient unit',
          maxLength: 40,
        );
        if (unitFailure != null) return unitFailure;
      }
    }

    return null;
  }

  Failure? _validateInstructionsLocally(
    List<AddRecipeInstruction> instructions,
  ) {
    for (final instruction in instructions) {
      if (_containsBlockedWord(instruction.description)) {
        return ValidationFailure(
          message: 'Instruction contains inappropriate language.',
        );
      }

      final sectionTitle = instruction.sectionTitle?.trim() ?? '';
      if (sectionTitle.isNotEmpty && _containsBlockedWord(sectionTitle)) {
        return ValidationFailure(
          message: 'Instruction section contains inappropriate language.',
        );
      }
    }

    return null;
  }

  Failure? _validateHumanText(
    String value, {
    required String fieldName,
    required int maxLength,
    bool allowEmpty = false,
  }) {
    final text = value.trim();
    if (!allowEmpty && text.isEmpty) {
      return ValidationFailure(message: '$fieldName is required.');
    }
    if (text.isEmpty) return null;
    if (text.length > maxLength) {
      return ValidationFailure(message: '$fieldName is too long.');
    }
    if (RegExp(r'https?://|www\.').hasMatch(text.toLowerCase())) {
      return ValidationFailure(
        message: '$fieldName cannot contain links.',
      );
    }
    if (RegExp(r'(.)\1{9,}').hasMatch(text)) {
      return ValidationFailure(message: '$fieldName looks unusual.');
    }
    if (_containsBlockedWord(text)) {
      return ValidationFailure(
        message: '$fieldName contains inappropriate language.',
      );
    }
    return null;
  }

  bool _containsBlockedWord(String value) {
    final normalized = value.toLowerCase();
    const blockedWords = [
      'fuck',
      'shit',
      'bitch',
      'asshole',
      'bastard',
      'slut',
      'whore',
      'cunt',
      'nigger',
      'nigga',
      'faggot',
      'retard',
    ];
    return blockedWords.any(
      (word) => RegExp('\\b${RegExp.escape(word)}\\b').hasMatch(normalized),
    );
  }
}
