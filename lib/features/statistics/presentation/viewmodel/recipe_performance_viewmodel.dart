import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/recipe_performance_statistics.dart';
import '../../domain/usecases/get_recipe_performance_statistics_usecase.dart';

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

  RecipePerformanceStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedRecipeId => _selectedRecipeId;

  RecipePerformanceItem? get selectedRecipe {
    final statistics = _statistics;
    final selectedId = _selectedRecipeId;
    if (statistics == null || selectedId == null) return null;
    for (final recipe in statistics.recipes) {
      if (recipe.id == selectedId) return recipe;
    }
    return null;
  }

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

  void selectRecipe(String recipeId) {
    if (_selectedRecipeId == recipeId) return;
    _selectedRecipeId = recipeId;
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
