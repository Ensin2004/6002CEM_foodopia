// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/post_difficulty_statistics.dart';
import '../../domain/usecases/get_post_difficulty_statistics_usecase.dart';

// Handles PostDifficultyViewModel for this part of the statistics page.
class PostDifficultyViewModel extends ChangeNotifier {
  final GetPostDifficultyStatisticsUseCase _getStatisticsUseCase;

  PostDifficultyStatistics? _statistics;
  bool _isLoading = true;
  bool _isDisposed = false;
  String? _errorMessage;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _expandedDifficulty;

  PostDifficultyViewModel({
    required GetPostDifficultyStatisticsUseCase getStatisticsUseCase,
  }) : _getStatisticsUseCase = getStatisticsUseCase {
    Future.microtask(loadStatistics);
  }

  // Handles statistics for this part of the statistics page.
  PostDifficultyStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get startDate => _startDate;
  // Handles endDate for this part of the statistics page.
  DateTime? get endDate => _endDate;
  int? get expandedDifficulty => _expandedDifficulty;

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

  // Handles toggleDifficulty for this part of the statistics page.
  void toggleDifficulty(int difficulty) {
    _expandedDifficulty = _expandedDifficulty == difficulty ? null : difficulty;
    _notifyIfActive();
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
