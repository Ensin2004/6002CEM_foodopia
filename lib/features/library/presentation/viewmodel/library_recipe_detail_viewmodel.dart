import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/library_recipe.dart';
import '../../domain/usecases/get_library_recipe_detail_usecase.dart';

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
    Future.microtask(loadRecipe);
  }

  LibraryRecipe? get recipe => _recipe;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadRecipe() async {
    _isLoading = _recipe == null;
    _errorMessage = null;
    _notifyIfActive();

    final result = await _getRecipeDetailUseCase.execute(recipeId);
    if (_isDisposed) return;

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
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
