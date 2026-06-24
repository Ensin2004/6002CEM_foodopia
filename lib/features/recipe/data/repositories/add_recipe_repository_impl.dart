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

/// Repository implementation that wraps remote add-recipe calls in failure-safe
/// results and applies local validation before expensive network operations.
class AddRecipeRepositoryImpl implements AddRecipeRepository {
  final AddRecipeRemoteDataSource remoteDataSource;

  const AddRecipeRepositoryImpl({required this.remoteDataSource});

  @override
  /// Loads basic form setup data and returns a user-facing failure on error.
  Future<Either<Failure, AddRecipeSetup>> getSetup() async {
    try {
      final setup = await remoteDataSource.getSetup();
      return Right(setup);
    } catch (_) {
      return Left(ServerFailure(message: 'Unable to load recipe categories.'));
    }
  }

  @override
  /// Loads ingredient units for unit pickers and maps failures into server errors.
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
  /// Loads active ingredient categories for ingredient analysis and review.
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
  /// Searches USDA foods after picker input and returns searchable result rows.
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
  /// Loads nutrients for a selected USDA food id.
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
  /// Loads an optional image URL for a named ingredient.
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
  /// Validates basic recipe fields, checks content policy and saves recipe metadata.
  Future<Either<Failure, String>> saveBasicInfo(AddRecipeBasicInfo info) async {
    // Local checks catch missing required form fields before remote validation runs.
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
      // AI moderation runs before Firestore save so rejected text stays out of drafts.
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
  /// Generates a complete editable recipe draft from uploaded video media.
  Future<Either<Failure, AddRecipeVideoResult>> generateRecipeFromVideo(
    String videoPath,
  ) async {
    // Empty or invalid media paths cannot produce a video recipe draft.
    if (videoPath.trim().isEmpty) {
      return Left(ValidationFailure(message: 'Please select a video.'));
    }

    try {
      final result = await remoteDataSource.generateRecipeFromVideo(videoPath);
      // Video generation must provide both ingredients and steps before the draft is usable.
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
  /// Generates recipe ingredients and instructions from an uploaded food image.
  Future<Either<Failure, AddRecipeImageResult>> generateRecipeFromImage(
    File imageFile,
  ) async {
    // Image generation starts only after a real local image file is selected.
    if (imageFile.path.trim().isEmpty || !await imageFile.exists()) {
      return Left(ValidationFailure(message: 'Please select an image.'));
    }

    try {
      final result = await remoteDataSource.generateRecipeFromImage(imageFile);
      // Generated image drafts need core recipe text, ingredients, and instructions.
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
  /// Validates ingredient rows, checks AI content policy and saves ingredients.
  Future<Either<Failure, void>> saveIngredients({
    required String recipeId,
    required List<AddRecipeIngredient> ingredients,
  }) async {
    // Required ingredient fields are checked locally for faster form feedback.
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
      // Remote validation checks ingredient text before image upload and Firestore writes.
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
  /// Validates cooking instructions, checks AI content policy and saves steps.
  Future<Either<Failure, void>> saveInstructions({
    required String recipeId,
    required bool useSections,
    required List<AddRecipeInstruction> instructions,
  }) async {
    // Instruction rows need valid text, ordering, and section labels before saving.
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
      // Content validation keeps unsafe instruction text from becoming saved recipe data.
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
  /// Loads review data for final recipe confirmation.
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
  /// Finalizes the recipe after validating review content remotely.
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
  /// Changes recipe visibility after validating the requested visibility value.
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
  /// Deletes a recipe and returns a readable failure when deletion is blocked.
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
  /// Marks generated or manual recipe creation as complete.
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

  /// Validate recipe basic info and return failure if content is inappropriate
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

  /// Validate recipe ingredients and return failure if content is inappropriate
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

  /// Validate recipe instructions and return failure if content is inappropriate
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

  /// Helper to validate user input
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
      return ValidationFailure(message: '$fieldName cannot contain links.');
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

  /// Helper to check whether content contain blocked word
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
