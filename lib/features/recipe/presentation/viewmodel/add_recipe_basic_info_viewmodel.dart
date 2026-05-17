import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/add_recipe_basic_info.dart';
import '../../domain/entities/add_recipe_setup.dart';
import '../../domain/usecases/get_add_recipe_setup_usecase.dart';
import '../../domain/usecases/save_add_recipe_basic_info_usecase.dart';

class AddRecipeBasicInfoViewModel extends ChangeNotifier {
  final GetAddRecipeSetupUseCase getSetupUseCase;
  final SaveAddRecipeBasicInfoUseCase saveBasicInfoUseCase;

  AddRecipeSetup? setup;
  bool isLoading = true;
  bool isSaving = false;
  String? errorMessage;
  String? savedRecipeId;
  int difficultyLevel = 0;

  AddRecipeBasicInfoViewModel({
    required this.getSetupUseCase,
    required this.saveBasicInfoUseCase,
  }) {
    loadSetup();
  }

  Future<void> loadSetup() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await getSetupUseCase.execute();
    if (result.isLeft()) {
      errorMessage = result.left?.message ?? 'Unable to load recipe setup.';
    } else {
      setup = result.right;
      difficultyLevel = 0;
    }

    isLoading = false;
    notifyListeners();
  }

  void selectDifficulty(int value) {
    difficultyLevel = value < 1
        ? 1
        : value > 5
        ? 5
        : value;
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> saveBasicInfo(AddRecipeBasicInfo info) async {
    isSaving = true;
    errorMessage = null;
    notifyListeners();

    final result = await saveBasicInfoUseCase.execute(info);
    final success = result.isRight();
    if (!success) {
      errorMessage = result.left?.message ?? 'Unable to save basic info.';
      savedRecipeId = null;
    } else {
      savedRecipeId = result.right;
    }

    isSaving = false;
    notifyListeners();
    return success;
  }
}
