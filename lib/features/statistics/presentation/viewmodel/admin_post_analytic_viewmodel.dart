import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/admin_statistics.dart';
import '../../domain/entities/recipe_performance_statistics.dart';
import '../../domain/usecases/get_admin_post_analytic_statistics_usecase.dart';

class AdminPostAnalyticViewModel extends ChangeNotifier {
  final GetAdminPostAnalyticStatisticsUseCase _getStatisticsUseCase;

  AdminPostAnalyticStatistics? _statistics;
  bool _isLoading = true;
  bool _isDisposed = false;
  String? _errorMessage;
  DateTime? _startDate;
  DateTime? _endDate;
  int _selectedSectionIndex = 0;
  String? _selectedRecipeId;
  AdminStatisticsSortOrder _sortOrder = AdminStatisticsSortOrder.descending;

  AdminPostAnalyticViewModel({
    required GetAdminPostAnalyticStatisticsUseCase getStatisticsUseCase,
  }) : _getStatisticsUseCase = getStatisticsUseCase {
    Future.microtask(loadStatistics);
  }

  AdminPostAnalyticStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  int get selectedSectionIndex => _selectedSectionIndex;
  String? get selectedRecipeId => _selectedRecipeId;
  AdminStatisticsSortOrder get sortOrder => _sortOrder;

  RecipePerformanceItem? get selectedRecipe {
    final statistics = _statistics?.recipePerformance;
    final selectedId = _selectedRecipeId;
    if (statistics == null || selectedId == null) return null;
    for (final recipe in statistics.recipes) {
      if (recipe.id == selectedId) return recipe;
    }
    return null;
  }

  AdminAnalyticSection? get selectedSection {
    final sections = _statistics?.sections;
    if (sections == null || sections.isEmpty) return null;
    return sections[_selectedSectionIndex.clamp(0, sections.length - 1)].sorted(
      _sortOrder,
    );
  }

  Future<void> loadStatistics() async {
    _isLoading = _statistics == null;
    _errorMessage = null;
    _notifyIfActive();

    final result = await _getStatisticsUseCase.execute(
      startDate: _startDate,
      endDate: _endDate,
    );
    if (_isDisposed) return;

    result.ifRight((statistics) {
      _statistics = statistics;
      if (_selectedRecipeId != null &&
          !(statistics.recipePerformance?.recipes.any(
                (recipe) => recipe.id == _selectedRecipeId,
              ) ??
              false)) {
        _selectedRecipeId = null;
      }
    });
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    _isLoading = false;
    _notifyIfActive();
  }

  void selectSection(int index) {
    if (_selectedSectionIndex == index) return;
    _selectedSectionIndex = index;
    _sortOrder = AdminStatisticsSortOrder.descending;
    _notifyIfActive();
  }

  void setSortOrder(AdminStatisticsSortOrder order) {
    if (_sortOrder == order) return;
    _sortOrder = order;
    _notifyIfActive();
  }

  void selectRecipe(String recipeId) {
    if (_selectedRecipeId == recipeId) return;
    _selectedRecipeId = recipeId;
    _notifyIfActive();
  }

  Future<void> selectDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _startDate = startDate;
    _endDate = endDate;
    await loadStatistics();
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
