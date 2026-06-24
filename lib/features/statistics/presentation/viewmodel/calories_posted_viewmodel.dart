import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/calories_intake_statistics.dart';
import '../../domain/entities/calories_posted_statistics.dart';
import '../../domain/usecases/get_calories_posted_statistics_usecase.dart';

// Handles CaloriesPostedViewModel for this part of the statistics page.
class CaloriesPostedViewModel extends ChangeNotifier {
  final GetCaloriesPostedStatisticsUseCase _getStatisticsUseCase;

  CaloriesPostedStatistics? _statistics;
  bool _isLoading = true;
  bool _isDisposed = false;
  String? _errorMessage;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _expandedIndex;
  CaloriesDisplayUnit _displayUnit = CaloriesDisplayUnit.kcal;

  CaloriesPostedViewModel({
    required GetCaloriesPostedStatisticsUseCase getStatisticsUseCase,
  }) : _getStatisticsUseCase = getStatisticsUseCase {
    Future.microtask(loadStatistics);
  }

  // Handles statistics for this part of the statistics page.
  CaloriesPostedStatistics? get statistics {
    final current = _statistics;
    if (current == null) return null;
    final sortedDays = [...current.dailyPosts]
      ..sort((left, right) => left.date.compareTo(right.date));
    return CaloriesPostedStatistics(
      dateRange: current.dateRange,
      totalPost: current.totalPost,
      averageCaloriesKcal: current.averageCaloriesKcal,
      averageCarbohydrateGram: current.averageCarbohydrateGram,
      averageProteinGram: current.averageProteinGram,
      averageFatGram: current.averageFatGram,
      dailyPosts: sortedDays,
    );
  }

  // Handles isLoading for this part of the statistics page.
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  // Handles expandedIndex for this part of the statistics page.
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
    return _displayUnit == CaloriesDisplayUnit.kcal ? kcal : kcal * 1000;
  }

  // Handles unitLabel for this part of the statistics page.
  String get unitLabel {
    return _displayUnit == CaloriesDisplayUnit.kcal ? 'kcal' : 'cal';
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
