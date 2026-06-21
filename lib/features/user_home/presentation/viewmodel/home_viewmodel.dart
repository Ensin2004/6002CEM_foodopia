import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/user_home_dashboard.dart';
import '../../domain/usecases/get_user_home_dashboard_usecase.dart';
import '../../domain/usecases/get_user_home_weather_usecase.dart';

/// ViewModel for the home page.
/// Manages state for the home dashboard and weather data.
class HomeViewModel extends ChangeNotifier {
  // =========================================================================
  // DEPENDENCIES
  // =========================================================================

  /// Name of the current user.
  final String userName;

  /// Use case for fetching the home dashboard.
  final GetUserHomeDashboardUseCase _getDashboardUseCase;

  /// Use case for fetching weather data.
  final GetUserHomeWeatherUseCase _getWeatherUseCase;

  // =========================================================================
  // STATE
  // =========================================================================

  /// Whether data is loading.
  bool _isLoading = true;

  /// Whether weather data is loading.
  bool _isWeatherLoading = false;

  /// Error message from loading.
  String? _errorMessage;

  /// Error message from weather.
  String? _weatherErrorMessage;

  /// The home dashboard data.
  UserHomeDashboard? _dashboard;

  /// Whether the ViewModel has been disposed.
  bool _isDisposed = false;

  // =========================================================================
  // CONSTRUCTOR
  // =========================================================================

  /// Creates a new home view model instance.
  HomeViewModel({
    required this.userName,
    required GetUserHomeDashboardUseCase getDashboardUseCase,
    required GetUserHomeWeatherUseCase getWeatherUseCase,
  }) : _getDashboardUseCase = getDashboardUseCase,
       _getWeatherUseCase = getWeatherUseCase {
    // Load the dashboard asynchronously after construction.
    Future.microtask(loadDashboard);
  }

  // =========================================================================
  // GETTERS
  // =========================================================================

  /// Whether data is loading.
  bool get isLoading => _isLoading;

  /// Whether weather data is loading.
  bool get isWeatherLoading => _isWeatherLoading;

  /// Error message from loading.
  String? get errorMessage => _errorMessage;

  /// Error message from weather.
  String? get weatherErrorMessage => _weatherErrorMessage;

  /// The home dashboard data.
  UserHomeDashboard? get dashboard => _dashboard;

  // =========================================================================
  // LOAD DASHBOARD
  // =========================================================================

  /// Loads the home dashboard.
  Future<void> loadDashboard() async {
    // Determine if page loading should be shown.
    final shouldShowPageLoading = _dashboard == null;

    // Set loading state.
    _isLoading = shouldShowPageLoading;
    _errorMessage = null;
    _notifyIfActive();

    try {
      // Execute the use case.
      final dashboardResult = await _getDashboardUseCase.execute(userName);

      // Check if disposed.
      if (_isDisposed) return;

      // Handle result.
      dashboardResult.ifLeft((failure) => _errorMessage = failure.message);
      dashboardResult.ifRight((dashboard) {
        _dashboard = dashboard;
        _isWeatherLoading = true;
      });
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      if (!_isDisposed) {
        // Reset loading state.
        _isLoading = false;
        _notifyIfActive();
      }
    }

    if (_isDisposed) return;

    // Refresh weather data.
    await refreshWeather();
  }

  // =========================================================================
  // REFRESH WEATHER
  // =========================================================================

  /// Refreshes the weather data.
  Future<void> refreshWeather() async {
    // Get the current dashboard.
    final currentDashboard = _dashboard;

    // Return if no dashboard.
    if (currentDashboard == null) return;

    // Set weather loading state.
    _isWeatherLoading = true;
    _weatherErrorMessage = null;
    _notifyIfActive();

    // Execute the use case.
    final weatherResult = await _getWeatherUseCase.execute();

    // Check if disposed.
    if (_isDisposed) return;

    // Handle result.
    weatherResult.ifRight((weather) {
      _dashboard = currentDashboard.copyWith(weather: weather);
    });
    weatherResult.ifLeft((failure) {
      _weatherErrorMessage = failure.message;
    });

    // Reset weather loading state.
    _isWeatherLoading = false;
    _notifyIfActive();
  }

  // =========================================================================
  // PRIVATE HELPERS
  // =========================================================================

  /// Notifies listeners if the ViewModel is not disposed.
  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  // =========================================================================
  // DISPOSAL
  // =========================================================================

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
