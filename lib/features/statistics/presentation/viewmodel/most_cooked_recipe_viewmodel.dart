import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/most_cooked_recipe_statistics.dart';
import '../../domain/usecases/get_most_cooked_recipe_statistics_usecase.dart';

class MostCookedRecipeViewModel extends ChangeNotifier {
  final GetMostCookedRecipeStatisticsUseCase _getStatisticsUseCase;

  MostCookedRecipeStatistics? _statistics;
  bool _isLoading = true;
  bool _isDisposed = false;
  String? _errorMessage;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _expandedIndex;
  MostCookedRecipeSortOrder _sortOrder = MostCookedRecipeSortOrder.highest;

  MostCookedRecipeViewModel({
    required GetMostCookedRecipeStatisticsUseCase getStatisticsUseCase,
  }) : _getStatisticsUseCase = getStatisticsUseCase {
    Future.microtask(loadStatistics);
  }

  MostCookedRecipeStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  int? get expandedIndex => _expandedIndex;
  MostCookedRecipeSortOrder get sortOrder => _sortOrder;

  List<MostCookedRecipeItem> get sortedRecipes {
    final items = [...?_statistics?.recipes];
    items.sort((left, right) {
      final result = right.quantity.compareTo(left.quantity);
      return _sortOrder == MostCookedRecipeSortOrder.highest ? result : -result;
    });
    return items;
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
    });
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    _isLoading = false;
    _notifyIfActive();
  }

  void setSortOrder(MostCookedRecipeSortOrder order) {
    if (_sortOrder == order) return;
    _sortOrder = order;
    _expandedIndex = null;
    _notifyIfActive();
  }

  void toggleRecipe(int index) {
    _expandedIndex = _expandedIndex == index ? null : index;
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
