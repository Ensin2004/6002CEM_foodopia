import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/statistics_dashboard.dart';
import '../../domain/usecases/get_statistics_dashboard_usecase.dart';

// View model for the main statistics page.
// It loads dashboard data through the use case, stores loading/error state,
// and tells the screen to rebuild when the selected tab or hero card changes.
class StatisticsViewModel extends ChangeNotifier {
  final GetStatisticsDashboardUseCase _getDashboardUseCase;
  final bool isAdmin;

  StatisticsDashboard? _dashboard;
  bool _isLoading = true;
  bool _isDisposed = false;
  String? _errorMessage;
  int _selectedAudienceIndex = 0;
  int _selectedHeroIndex = 0;

  StatisticsViewModel({
    required this.isAdmin,
    required GetStatisticsDashboardUseCase getDashboardUseCase,
  }) : _getDashboardUseCase = getDashboardUseCase {
    Future.microtask(loadStatistics);
  }

  StatisticsDashboard? get dashboard => _dashboard;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get selectedAudienceIndex => _selectedAudienceIndex;
  int get selectedHeroIndex => _selectedHeroIndex;

  Future<void> loadStatistics() async {
    // Ask the domain layer for the dashboard data. The view model only keeps
    // the result for the UI; it does not read Firestore directly.
    _isLoading = _dashboard == null;
    _errorMessage = null;
    _notifyIfActive();

    final result = await _getDashboardUseCase.execute(isAdmin: isAdmin);
    if (_isDisposed) return;

    result.ifRight((dashboard) {
      _dashboard = dashboard;
    });
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    _isLoading = false;
    _notifyIfActive();
  }

  void selectAudience(int index) {
    // Switches between personal and community/admin sections on the screen.
    if (_selectedAudienceIndex == index) return;
    _selectedAudienceIndex = index;
    _selectedHeroIndex = 0;
    _notifyIfActive();
  }

  void selectHero(int index) {
    // Updates which top statistics card is currently selected.
    if (_selectedHeroIndex == index) return;
    _selectedHeroIndex = index;
    _notifyIfActive();
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
