// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/calories_intake_statistics.dart';
import '../../domain/usecases/get_admin_nutrient_insight_statistics_usecase.dart';

// Handles AdminNutrientInsightViewModel for this part of the statistics page.
class AdminNutrientInsightViewModel extends ChangeNotifier {
  final GetAdminNutrientInsightStatisticsUseCase _getStatisticsUseCase;

  CaloriesIntakeStatistics? _statistics;
  bool _isLoading = true;
  bool _isDisposed = false;
  String? _errorMessage;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _expandedIndex;
  CaloriesDisplayUnit _displayUnit = CaloriesDisplayUnit.kcal;

  AdminNutrientInsightViewModel({
    required GetAdminNutrientInsightStatisticsUseCase getStatisticsUseCase,
  }) : _getStatisticsUseCase = getStatisticsUseCase {
    Future.microtask(loadStatistics);
  }

  // Handles statistics for this part of the statistics page.
  CaloriesIntakeStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get startDate => _startDate;
  // Handles endDate for this part of the statistics page.
  DateTime? get endDate => _endDate;
  int? get expandedIndex => _expandedIndex;
  CaloriesDisplayUnit get displayUnit => _displayUnit;

  // Handles loadStatistics for this part of the statistics page.
  Future<void> loadStatistics() async {
    _isLoading = _statistics == null;
    _errorMessage = null;
    _notifyIfActive();

    final result = await _getStatisticsUseCase.execute(
      startDate: _startDate,
      endDate: _endDate,
    );
    if (_isDisposed) return;

    result.ifRight((statistics) => _statistics = statistics);
    result.ifLeft((failure) => _errorMessage = failure.message);

    _isLoading = false;
    _notifyIfActive();
  }

  // Handles setDisplayUnit for this part of the statistics page.
  void setDisplayUnit(CaloriesDisplayUnit unit) {
    if (_displayUnit == unit) return;
    _displayUnit = unit;
    _notifyIfActive();
  }

  // Handles toggleDay for this part of the statistics page.
  void toggleDay(int index) {
    _expandedIndex = _expandedIndex == index ? null : index;
    _notifyIfActive();
  }

  // Handles convertCalories for this part of the statistics page.
  int convertCalories(int kcal) {
    switch (_displayUnit) {
      case CaloriesDisplayUnit.kcal:
        return kcal;
      case CaloriesDisplayUnit.cal:
        return kcal * 1000;
    }
  }

  // Handles unitLabel for this part of the statistics page.
  String get unitLabel {
    switch (_displayUnit) {
      case CaloriesDisplayUnit.kcal:
        return 'kcal';
      case CaloriesDisplayUnit.cal:
        return 'cal';
    }
  }

  // Handles selectDateRange for this part of the statistics page.
  Future<void> selectDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    _startDate = startDate;
    _endDate = endDate;
    await loadStatistics();
  }

  // Handles _notifyIfActive for this part of the statistics page.
  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  // Handles dispose for this part of the statistics page.
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
