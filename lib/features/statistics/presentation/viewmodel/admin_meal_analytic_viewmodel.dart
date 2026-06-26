import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/admin_statistics.dart';
import '../../domain/usecases/get_admin_meal_analytic_statistics_usecase.dart';

// Handles AdminMealAnalyticViewModel for this part of the statistics page.
class AdminMealAnalyticViewModel extends ChangeNotifier {
  final GetAdminMealAnalyticStatisticsUseCase _getStatisticsUseCase;

  AdminMealAnalyticStatistics? _statistics;
  bool _isLoading = true;
  bool _isDisposed = false;
  String? _errorMessage;
  DateTime? _startDate;
  DateTime? _endDate;
  int _selectedSectionIndex = 0;
  AdminStatisticsSortOrder _sortOrder = AdminStatisticsSortOrder.descending;

  AdminMealAnalyticViewModel({
    required GetAdminMealAnalyticStatisticsUseCase getStatisticsUseCase,
  }) : _getStatisticsUseCase = getStatisticsUseCase {
    Future.microtask(loadStatistics);
  }

  // Handles statistics for this part of the statistics page.
  AdminMealAnalyticStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get startDate => _startDate;
  // Handles endDate for this part of the statistics page.
  DateTime? get endDate => _endDate;
  int get selectedSectionIndex => _selectedSectionIndex;
  AdminStatisticsSortOrder get sortOrder => _sortOrder;

  // Handles selectedSection for this part of the statistics page.
  AdminAnalyticSection? get selectedSection {
    final sections = _statistics?.sections;
    if (sections == null || sections.isEmpty) return null;
    return sections[_selectedSectionIndex.clamp(0, sections.length - 1)].sorted(
      _sortOrder,
    );
  }

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

    result.ifRight((statistics) {
      _statistics = statistics;
    });
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    _isLoading = false;
    _notifyIfActive();
  }

  // Handles selectSection for this part of the statistics page.
  void selectSection(int index) {
    if (_selectedSectionIndex == index) return;
    _selectedSectionIndex = index;
    _sortOrder = AdminStatisticsSortOrder.descending;
    _notifyIfActive();
  }

  // Handles setSortOrder for this part of the statistics page.
  void setSortOrder(AdminStatisticsSortOrder order) {
    if (_sortOrder == order) return;
    _sortOrder = order;
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
