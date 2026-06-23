import 'package:flutter/foundation.dart';

import '../../domain/entities/admin_home_dashboard.dart';
import '../../domain/usecases/get_admin_home_dashboard_usecase.dart';

/// ViewModel for the admin home page.
/// Manages state for the admin home dashboard.
class AdminHomeViewModel extends ChangeNotifier {
  // =========================================================================
  // DEPENDENCIES
  // =========================================================================

  /// Name of the admin user.
  final String adminName;

  /// Use case for fetching the admin home dashboard.
  final GetAdminHomeDashboardUseCase _getDashboardUseCase;

  // =========================================================================
  // STATE
  // =========================================================================

  /// Whether data is loading.
  bool _isLoading = true;

  /// Error message from loading.
  String? _errorMessage;

  /// The admin home dashboard data.
  AdminHomeDashboard? _dashboard;

  /// Whether this view model has been disposed.
  bool _isDisposed = false;

  // =========================================================================
  // CONSTRUCTOR
  // =========================================================================

  /// Creates a new admin home view model instance.
  AdminHomeViewModel({
    required this.adminName,
    required GetAdminHomeDashboardUseCase getDashboardUseCase,
  }) : _getDashboardUseCase = getDashboardUseCase {
    // Load the dashboard asynchronously after construction.
    Future.microtask(loadDashboard);
  }

  // =========================================================================
  // GETTERS
  // =========================================================================

  /// Whether data is loading.
  bool get isLoading => _isLoading;

  /// Error message from loading.
  String? get errorMessage => _errorMessage;

  /// The admin home dashboard data.
  AdminHomeDashboard? get dashboard => _dashboard;

  // =========================================================================
  // LOAD DASHBOARD
  // =========================================================================

  /// Loads the admin home dashboard.
  Future<void> loadDashboard() async {
    if (_isDisposed) return;

    // Set loading state.
    _isLoading = true;
    _errorMessage = null;
    _notifyIfActive();

    // Execute the use case.
    final result = await _getDashboardUseCase.execute(adminName);
    if (_isDisposed) return;

    // Handle result.
    result.fold(
      (failure) => _errorMessage = failure.message,
      (dashboard) => _dashboard = dashboard,
    );

    // Reset loading state.
    _isLoading = false;
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
