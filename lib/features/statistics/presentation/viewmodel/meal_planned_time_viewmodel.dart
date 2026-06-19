// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/meal_planned_time_statistics.dart';
import '../../domain/usecases/get_meal_planned_time_statistics_usecase.dart';

// Handles MealPlannedTimeViewModel for this part of the statistics page.
// This makes the purpose clearer when reading or updating the code.
class MealPlannedTimeViewModel extends ChangeNotifier {
  final GetMealPlannedTimeStatisticsUseCase _getStatisticsUseCase;

  MealPlannedTimeStatistics? _statistics;
  bool _isLoading = true;
  bool _isDisposed = false;
  String? _errorMessage;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _expandedIndex;

  MealPlannedTimeViewModel({
    required GetMealPlannedTimeStatisticsUseCase getStatisticsUseCase,
  }) : _getStatisticsUseCase = getStatisticsUseCase {
    Future.microtask(loadStatistics);
  }

  // Handles statistics for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  MealPlannedTimeStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get startDate => _startDate;
  // Handles endDate for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  DateTime? get endDate => _endDate;
  int? get expandedIndex => _expandedIndex;

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

  // Handles toggleBreakdown for this part of the statistics page.
  // This makes the purpose clearer when reading or updating the code.
  void toggleBreakdown(int index) {
    _expandedIndex = _expandedIndex == index ? null : index;
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
