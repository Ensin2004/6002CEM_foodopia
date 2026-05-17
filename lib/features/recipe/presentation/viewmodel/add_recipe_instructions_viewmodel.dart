import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/add_recipe_instruction.dart';
import '../../domain/usecases/save_add_recipe_instructions_usecase.dart';

class AddRecipeInstructionsViewModel extends ChangeNotifier {
  final SaveAddRecipeInstructionsUseCase saveInstructionsUseCase;

  bool isSaving = false;
  String? errorMessage;

  AddRecipeInstructionsViewModel({required this.saveInstructionsUseCase});

  Future<bool> saveInstructions({
    required String recipeId,
    required bool useSections,
    required List<AddRecipeInstruction> instructions,
  }) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    final result = await saveInstructionsUseCase.execute(
      recipeId: recipeId,
      useSections: useSections,
      instructions: instructions,
    );
    final success = result.isRight();
    if (!success) {
      errorMessage = result.left?.message ?? 'Unable to save instructions.';
    }

    isSaving = false;
    notifyListeners();
    return success;
  }
}
