// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/calories_intake_statistics.dart';
import '../../domain/usecases/get_calories_intake_statistics_usecase.dart';

// Handles CaloriesIntakeViewModel for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class CaloriesIntakeViewModel extends ChangeNotifier {
  final GetCaloriesIntakeStatisticsUseCase _getStatisticsUseCase;

  CaloriesIntakeStatistics? _statistics;
  bool _isLoading = true;
  bool _isDisposed = false;
  String? _errorMessage;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _expandedIndex;
  CaloriesDisplayUnit _displayUnit = CaloriesDisplayUnit.kcal;

  CaloriesIntakeViewModel({
    required GetCaloriesIntakeStatisticsUseCase getStatisticsUseCase,
  }) : _getStatisticsUseCase = getStatisticsUseCase {
    Future.microtask(loadStatistics);
  }

  // Handles statistics for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  CaloriesIntakeStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get startDate => _startDate;
  // Handles endDate for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  DateTime? get endDate => _endDate;
  int? get expandedIndex => _expandedIndex;
  CaloriesDisplayUnit get displayUnit => _displayUnit;

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

  // Handles setDisplayUnit for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  void setDisplayUnit(CaloriesDisplayUnit unit) {
    if (_displayUnit == unit) return;
    _displayUnit = unit;
    _notifyIfActive();
  }

  // Handles toggleDay for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  void toggleDay(int index) {
    _expandedIndex = _expandedIndex == index ? null : index;
    _notifyIfActive();
  }

  // Handles convertCalories for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  int convertCalories(int kcal) {
    switch (_displayUnit) {
      case CaloriesDisplayUnit.kcal:
        return kcal;
      case CaloriesDisplayUnit.cal:
        return kcal * 1000;
    }
  }

  // Handles unitLabel for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  String get unitLabel {
    switch (_displayUnit) {
      case CaloriesDisplayUnit.kcal:
        return 'kcal';
      case CaloriesDisplayUnit.cal:
        return 'cal';
    }
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
