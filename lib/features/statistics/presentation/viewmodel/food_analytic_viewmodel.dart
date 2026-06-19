// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/food_analytic_statistics.dart';
import '../../domain/usecases/get_food_analytic_statistics_usecase.dart';

// Handles FoodAnalyticViewModel for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class FoodAnalyticViewModel extends ChangeNotifier {
  final GetFoodAnalyticStatisticsUseCase _getStatisticsUseCase;

  FoodAnalyticStatistics? _statistics;
  bool _isLoading = true;
  bool _isDisposed = false;
  String? _errorMessage;
  DateTime? _startDate;
  DateTime? _endDate;
  int _selectedChartIndex = 0;
  int? _expandedItemIndex;
  StatisticsSortOrder _sortOrder = StatisticsSortOrder.most;

  FoodAnalyticViewModel({
    required GetFoodAnalyticStatisticsUseCase getStatisticsUseCase,
  }) : _getStatisticsUseCase = getStatisticsUseCase {
    Future.microtask(loadStatistics);
  }

  // Handles statistics for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  FoodAnalyticStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get startDate => _startDate;
  // Handles endDate for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  DateTime? get endDate => _endDate;
  int get selectedChartIndex => _selectedChartIndex;
  int? get expandedItemIndex => _expandedItemIndex;
  StatisticsSortOrder get sortOrder => _sortOrder;

  // Handles selectedChart for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  FoodAnalyticChart? get selectedChart {
    final charts = _statistics?.charts;
    if (charts == null || charts.isEmpty) return null;
    return charts[_selectedChartIndex.clamp(0, charts.length - 1)].sorted(
      _sortOrder,
    );
  }

  // Handles loadStatistics for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
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

  // Handles selectChart for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  void selectChart(int index) {
    if (_selectedChartIndex == index) return;
    _selectedChartIndex = index;
    _expandedItemIndex = null;
    _sortOrder = StatisticsSortOrder.most;
    _notifyIfActive();
  }

  // Handles setSortOrder for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  void setSortOrder(StatisticsSortOrder order) {
    if (_sortOrder == order) return;
    _sortOrder = order;
    _expandedItemIndex = null;
    _notifyIfActive();
  }

  // Handles toggleItem for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  void toggleItem(int index) {
    _expandedItemIndex = _expandedItemIndex == index ? null : index;
    _notifyIfActive();
  }

  // Handles selectDateRange for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  Future<void> selectDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _startDate = startDate;
    _endDate = endDate;
    await loadStatistics();
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
