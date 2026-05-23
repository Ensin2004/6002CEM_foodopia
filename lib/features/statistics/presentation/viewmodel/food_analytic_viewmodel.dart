import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/food_analytic_statistics.dart';
import '../../domain/usecases/get_food_analytic_statistics_usecase.dart';

class FoodAnalyticViewModel extends ChangeNotifier {
  final GetFoodAnalyticStatisticsUseCase _getStatisticsUseCase;

  FoodAnalyticStatistics? _statistics;
  bool _isLoading = true;
  bool _isDisposed = false;
  String? _errorMessage;
  DateTime? _startDate;
  DateTime? _endDate;
  int _selectedChartIndex = 0;
  StatisticsSortOrder _sortOrder = StatisticsSortOrder.most;

  FoodAnalyticViewModel({
    required GetFoodAnalyticStatisticsUseCase getStatisticsUseCase,
  }) : _getStatisticsUseCase = getStatisticsUseCase {
    Future.microtask(loadStatistics);
  }

  FoodAnalyticStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  int get selectedChartIndex => _selectedChartIndex;
  StatisticsSortOrder get sortOrder => _sortOrder;

  FoodAnalyticChart? get selectedChart {
    final charts = _statistics?.charts;
    if (charts == null || charts.isEmpty) return null;
    return charts[_selectedChartIndex.clamp(0, charts.length - 1)].sorted(
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
    });
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    _isLoading = false;
    _notifyIfActive();
  }

  void selectChart(int index) {
    if (_selectedChartIndex == index) return;
    _selectedChartIndex = index;
    _sortOrder = StatisticsSortOrder.most;
    _notifyIfActive();
  }

  void setSortOrder(StatisticsSortOrder order) {
    if (_sortOrder == order) return;
    _sortOrder = order;
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
