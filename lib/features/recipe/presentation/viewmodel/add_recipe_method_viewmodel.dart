import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/usecases/complete_add_recipe_usecase.dart';
import '../../domain/usecases/generate_add_recipe_from_video_usecase.dart';
import '../../domain/usecases/save_add_recipe_basic_info_usecase.dart';
import '../../domain/usecases/save_add_recipe_ingredients_usecase.dart';
import '../../domain/usecases/save_add_recipe_instructions_usecase.dart';

enum AddRecipeMethod { uploadVideo, scratch }

class AddRecipeMethodViewModel extends ChangeNotifier {
  final GenerateAddRecipeFromVideoUseCase? generateFromVideoUseCase;
  final SaveAddRecipeBasicInfoUseCase? saveBasicInfoUseCase;
  final SaveAddRecipeIngredientsUseCase? saveIngredientsUseCase;
  final SaveAddRecipeInstructionsUseCase? saveInstructionsUseCase;
  final CompleteAddRecipeUseCase? completeRecipeUseCase;

  AddRecipeMethod? _selectedMethod;
  bool _isGeneratingVideoRecipe = false;
  String? _errorMessage;
  String? _generatedRecipeId;

  AddRecipeMethod? get selectedMethod => _selectedMethod;
  bool get isGeneratingVideoRecipe => _isGeneratingVideoRecipe;
  String? get errorMessage => _errorMessage;
  String? get generatedRecipeId => _generatedRecipeId;

  AddRecipeMethodViewModel({
    this.generateFromVideoUseCase,
    this.saveBasicInfoUseCase,
    this.saveIngredientsUseCase,
    this.saveInstructionsUseCase,
    this.completeRecipeUseCase,
  });

  void selectMethod(AddRecipeMethod method) {
    _selectedMethod = method;
    notifyListeners();
  }

  Future<bool> generateRecipeFromVideo(String videoPath) async {
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

    _isGeneratingVideoRecipe = true;
    _errorMessage = null;
    _generatedRecipeId = null;
    notifyListeners();

    final generated = await generateUseCase.execute(videoPath);
    if (generated.isLeft()) {
      return _finishWithError(generated.left?.message);
    }
    final draft = generated.right!;

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

  bool _finishWithError(String? message) {
    _errorMessage = message ?? 'Unable to generate recipe from video.';
    _isGeneratingVideoRecipe = false;
    notifyListeners();
    return false;
  }
}
