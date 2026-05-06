import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/user_home_dashboard.dart';
import '../../domain/usecases/get_user_home_dashboard_usecase.dart';
import '../../domain/usecases/get_user_home_weather_usecase.dart';

class HomeViewModel extends ChangeNotifier {
  final String userName;
  final GetUserHomeDashboardUseCase _getDashboardUseCase;
  final GetUserHomeWeatherUseCase _getWeatherUseCase;

  bool _isLoading = true;
  bool _isWeatherLoading = false;
  String? _errorMessage;
  String? _weatherErrorMessage;
  UserHomeDashboard? _dashboard;
  bool _isDisposed = false;

  HomeViewModel({
    required this.userName,
    required GetUserHomeDashboardUseCase getDashboardUseCase,
    required GetUserHomeWeatherUseCase getWeatherUseCase,
  }) : _getDashboardUseCase = getDashboardUseCase,
       _getWeatherUseCase = getWeatherUseCase {
    Future.microtask(loadDashboard);
  }

  bool get isLoading => _isLoading;
  bool get isWeatherLoading => _isWeatherLoading;
  String? get errorMessage => _errorMessage;
  String? get weatherErrorMessage => _weatherErrorMessage;
  UserHomeDashboard? get dashboard => _dashboard;

  Future<void> loadDashboard() async {
    final shouldShowPageLoading = _dashboard == null;
    _isLoading = shouldShowPageLoading;
    _errorMessage = null;
    _notifyIfActive();

    final dashboardResult = await _getDashboardUseCase.execute(userName);
    if (_isDisposed) return;

    dashboardResult.ifLeft((failure) => _errorMessage = failure.message);
    dashboardResult.ifRight((dashboard) {
      _dashboard = dashboard;
      _isWeatherLoading = true;
    });

    _isLoading = false;
    _notifyIfActive();

    await refreshWeather();
  }

  Future<void> refreshWeather() async {
    final currentDashboard = _dashboard;
    if (currentDashboard == null) return;

    _isWeatherLoading = true;
    _weatherErrorMessage = null;
    _notifyIfActive();

    final weatherResult = await _getWeatherUseCase.execute();
    if (_isDisposed) return;

    weatherResult.ifRight((weather) {
      _dashboard = currentDashboard.copyWith(weather: weather);
    });
    weatherResult.ifLeft((failure) {
      _weatherErrorMessage = failure.message;
    });

    _isWeatherLoading = false;
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
