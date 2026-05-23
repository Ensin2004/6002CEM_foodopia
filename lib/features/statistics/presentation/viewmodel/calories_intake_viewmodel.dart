import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/calories_intake_statistics.dart';
import '../../domain/usecases/get_calories_intake_statistics_usecase.dart';

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

  CaloriesIntakeStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  int? get expandedIndex => _expandedIndex;
  CaloriesDisplayUnit get displayUnit => _displayUnit;

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

  void setDisplayUnit(CaloriesDisplayUnit unit) {
    if (_displayUnit == unit) return;
    _displayUnit = unit;
    _notifyIfActive();
  }

  void toggleDay(int index) {
    _expandedIndex = _expandedIndex == index ? null : index;
    _notifyIfActive();
  }

  int convertCalories(int kcal) {
    switch (_displayUnit) {
      case CaloriesDisplayUnit.kcal:
        return kcal;
      case CaloriesDisplayUnit.cal:
        return kcal * 1000;
    }
  }

  String get unitLabel {
    switch (_displayUnit) {
      case CaloriesDisplayUnit.kcal:
        return 'kcal';
      case CaloriesDisplayUnit.cal:
        return 'cal';
    }
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
