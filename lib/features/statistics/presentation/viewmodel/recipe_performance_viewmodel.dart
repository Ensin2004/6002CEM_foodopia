// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/recipe_performance_statistics.dart';
import '../../domain/usecases/get_recipe_performance_statistics_usecase.dart';

// Handles RecipePerformanceViewModel for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class RecipePerformanceViewModel extends ChangeNotifier {
  final GetRecipePerformanceStatisticsUseCase _getStatisticsUseCase;

  RecipePerformanceStatistics? _statistics;
  bool _isLoading = true;
  bool _isDisposed = false;
  String? _errorMessage;
  String? _selectedRecipeId;

  RecipePerformanceViewModel({
    required GetRecipePerformanceStatisticsUseCase getStatisticsUseCase,
  }) : _getStatisticsUseCase = getStatisticsUseCase {
    Future.microtask(loadStatistics);
  }

  // Handles statistics for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  RecipePerformanceStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedRecipeId => _selectedRecipeId;

  // Handles selectedRecipe for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  RecipePerformanceItem? get selectedRecipe {
    final statistics = _statistics;
    final selectedId = _selectedRecipeId;
    if (statistics == null || selectedId == null) return null;
    for (final recipe in statistics.recipes) {
      if (recipe.id == selectedId) return recipe;
    }
    return null;
  }

  // Handles loadStatistics for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Future<void> loadStatistics() async {
    _isLoading = _statistics == null;
    _errorMessage = null;
    _notifyIfActive();

    final result = await _getStatisticsUseCase.execute();
    if (_isDisposed) return;

    result.ifRight((statistics) {
      _statistics = statistics;
      if (_selectedRecipeId != null &&
          !statistics.recipes.any((recipe) => recipe.id == _selectedRecipeId)) {
        _selectedRecipeId = null;
      }
    });
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    _isLoading = false;
    _notifyIfActive();
  }

  // Handles selectRecipe for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  void selectRecipe(String recipeId) {
    if (_selectedRecipeId == recipeId) return;
    _selectedRecipeId = recipeId;
    _notifyIfActive();
  }

  // Handles _notifyIfActive for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  // Handles dispose for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
