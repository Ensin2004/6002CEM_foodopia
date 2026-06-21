import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/library_recipe.dart';
import '../../domain/usecases/get_library_recipe_detail_usecase.dart';

// Manages loading, error, and recipe detail state for a selected library recipe.
class LibraryRecipeDetailViewModel extends ChangeNotifier {
  final GetLibraryRecipeDetailUseCase _getRecipeDetailUseCase;
  final String recipeId;

  LibraryRecipe? _recipe;
  bool _isLoading = true;
  bool _isDisposed = false;
  String? _errorMessage;

  LibraryRecipeDetailViewModel({
    required this.recipeId,
    required GetLibraryRecipeDetailUseCase getRecipeDetailUseCase,
  }) : _getRecipeDetailUseCase = getRecipeDetailUseCase {
    // Starts loading recipe details after construction so the page can render immediately.
    Future.microtask(loadRecipe);
  }

  LibraryRecipe? get recipe => _recipe;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadRecipe() async {
    // Shows the loading state only before the first recipe detail result has been loaded.
    _isLoading = _recipe == null;
    _errorMessage = null;
    _notifyIfActive();

    // Requests the selected recipe by id through the domain use case.
    final result = await _getRecipeDetailUseCase.execute(recipeId);
    if (_isDisposed) return;

    // Saves either the loaded recipe or the failure message for the detail page.
    result.ifRight((recipe) {
      _recipe = recipe;
    });
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    _isLoading = false;
    _notifyIfActive();
  }

  void _notifyIfActive() {
    // Prevents notifyListeners from running after the view model has been disposed.
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    // Marks the view model inactive before Flutter disposes listener resources.
    _isDisposed = true;
    super.dispose();
  }
}
