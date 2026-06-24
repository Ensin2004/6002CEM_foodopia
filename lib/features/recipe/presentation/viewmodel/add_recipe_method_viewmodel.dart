import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/add_recipe_image_result.dart';
import '../../domain/entities/add_recipe_ingredient.dart';
import '../../domain/usecases/complete_add_recipe_usecase.dart';
import '../../domain/usecases/generate_add_recipe_from_video_usecase.dart';
import '../../domain/usecases/generate_add_recipe_ingredients_from_image_usecase.dart';
import '../../domain/usecases/save_add_recipe_basic_info_usecase.dart';
import '../../domain/usecases/save_add_recipe_ingredients_usecase.dart';
import '../../domain/usecases/save_add_recipe_instructions_usecase.dart';

/// Recipe creation choices shown on the add-recipe method screen.
enum AddRecipeMethod { uploadImage, uploadVideo, scratch }

/// Controls recipe creation method selection plus AI image and video generation flows.
class AddRecipeMethodViewModel extends ChangeNotifier {
  final GenerateAddRecipeIngredientsFromImageUseCase?
  generateIngredientsFromImageUseCase;
  final GenerateAddRecipeFromVideoUseCase? generateFromVideoUseCase;
  final SaveAddRecipeBasicInfoUseCase? saveBasicInfoUseCase;
  final SaveAddRecipeIngredientsUseCase? saveIngredientsUseCase;
  final SaveAddRecipeInstructionsUseCase? saveInstructionsUseCase;
  final CompleteAddRecipeUseCase? completeRecipeUseCase;

  AddRecipeMethod? _selectedMethod;
  bool _isGeneratingImageIngredients = false;
  bool _isGeneratingVideoRecipe = false;
  String? _errorMessage;
  String? _generatedRecipeId;
  AddRecipeImageResult? _generatedImageRecipe;
  List<AddRecipeIngredient> _generatedImageIngredients = [];

  AddRecipeMethod? get selectedMethod => _selectedMethod;
  bool get isGeneratingImageIngredients => _isGeneratingImageIngredients;
  bool get isGeneratingVideoRecipe => _isGeneratingVideoRecipe;
  String? get errorMessage => _errorMessage;
  String? get generatedRecipeId => _generatedRecipeId;
  AddRecipeImageResult? get generatedImageRecipe => _generatedImageRecipe;
  List<AddRecipeIngredient> get generatedImageIngredients =>
      List.unmodifiable(_generatedImageIngredients);

  AddRecipeMethodViewModel({
    this.generateIngredientsFromImageUseCase,
    this.generateFromVideoUseCase,
    this.saveBasicInfoUseCase,
    this.saveIngredientsUseCase,
    this.saveInstructionsUseCase,
    this.completeRecipeUseCase,
  });

  /// Stores the selected creation method for the method selection screen.
  void selectMethod(AddRecipeMethod method) {
    _selectedMethod = method;
    notifyListeners();
  }

  /// Generates editable recipe ingredients and draft details from an uploaded image.
  Future<bool> generateIngredientsFromImage(File imageFile) async {
    // Missing image generation use case means the upload image feature is unavailable.
    final generateUseCase = generateIngredientsFromImageUseCase;
    if (generateUseCase == null) {
      _errorMessage = 'Upload image is not configured.';
      notifyListeners();
      return false;
    }

    // Previous generated image results are cleared before starting a fresh request.
    _isGeneratingImageIngredients = true;
    _errorMessage = null;
    _generatedImageRecipe = null;
    _generatedImageIngredients = [];
    notifyListeners();

    final result = await generateUseCase.execute(imageFile);
    if (result.isLeft()) {
      _errorMessage =
          result.left?.message ?? 'Unable to generate ingredients from image.';
      _isGeneratingImageIngredients = false;
      notifyListeners();
      return false;
    }

    // Generated ingredient data stays available for the next customization screen.
    _generatedImageRecipe = result.right;
    _generatedImageIngredients = _generatedImageRecipe?.ingredients ?? [];
    _isGeneratingImageIngredients = false;
    if (_generatedImageIngredients.isEmpty) {
      _errorMessage = 'Unable to detect ingredients from this image.';
      notifyListeners();
      return false;
    }
    notifyListeners();
    return true;
  }

  /// Generates, saves and completes a recipe draft from an uploaded video.
  Future<bool> generateRecipeFromVideo(String videoPath) async {
    // Video generation needs generation plus every save use case to finish the draft.
    final generateUseCase = generateFromVideoUseCase;
    final saveBasicInfo = saveBasicInfoUseCase;
    final saveIngredients = saveIngredientsUseCase;
    final saveInstructions = saveInstructionsUseCase;
    final completeRecipe = completeRecipeUseCase;
    if (generateUseCase == null ||
        saveBasicInfo == null ||
        saveIngredients == null ||
        saveInstructions == null ||
        completeRecipe == null) {
      _errorMessage = 'Upload video is not configured.';
      notifyListeners();
      return false;
    }

    // Video generation starts with a clean error and recipe id state.
    _isGeneratingVideoRecipe = true;
    _errorMessage = null;
    _generatedRecipeId = null;
    notifyListeners();

    final generated = await generateUseCase.execute(videoPath);
    if (generated.isLeft()) {
      return _finishWithError(generated.left?.message);
    }
    final draft = generated.right!;

    // Generated video drafts are saved through the same steps as manual recipe entry.
    final basicInfoResult = await saveBasicInfo.execute(draft.basicInfo);
    if (basicInfoResult.isLeft()) {
      return _finishWithError(basicInfoResult.left?.message);
    }
    final recipeId = basicInfoResult.right!;

    final ingredientsResult = await saveIngredients.execute(
      recipeId: recipeId,
      ingredients: draft.ingredients,
    );
    if (ingredientsResult.isLeft()) {
      return _finishWithError(ingredientsResult.left?.message);
    }

    final instructionsResult = await saveInstructions.execute(
      recipeId: recipeId,
      useSections: false,
      instructions: draft.instructions,
    );
    if (instructionsResult.isLeft()) {
      return _finishWithError(instructionsResult.left?.message);
    }

    final completeResult = await completeRecipe.execute(
      recipeId: recipeId,
      mode: 'ai_generated',
    );
    if (completeResult.isLeft()) {
      return _finishWithError(completeResult.left?.message);
    }

    _generatedRecipeId = recipeId;
    _isGeneratingVideoRecipe = false;
    notifyListeners();
    return true;
  }

  /// Stores generation failure text and resets the video loading state.
  bool _finishWithError(String? message) {
    _errorMessage = message ?? 'Unable to generate recipe from video.';
    _isGeneratingVideoRecipe = false;
    notifyListeners();
    return false;
  }
}
