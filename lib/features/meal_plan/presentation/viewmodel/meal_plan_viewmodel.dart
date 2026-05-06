import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/meal_plan_dashboard.dart';
import '../../domain/usecases/get_meal_plan_dashboard_usecase.dart';
import '../../domain/usecases/get_meal_plan_weather_usecase.dart';

enum MealPlanFilter { all, breakfast, lunch, dinner }

class MealPlanViewModel extends ChangeNotifier {
  final GetMealPlanDashboardUseCase _getDashboardUseCase;
  final GetMealPlanWeatherUseCase _getWeatherUseCase;

  MealPlanDashboard? _dashboard;
  MealPlanFilter _selectedFilter = MealPlanFilter.all;
  bool _isLoading = true;
  bool _isWeatherLoading = false;
  bool _isDisposed = false;
  String? _errorMessage;
  String? _weatherErrorMessage;

  MealPlanViewModel({
    required GetMealPlanDashboardUseCase getDashboardUseCase,
    required GetMealPlanWeatherUseCase getWeatherUseCase,
  }) : _getDashboardUseCase = getDashboardUseCase,
       _getWeatherUseCase = getWeatherUseCase {
    Future.microtask(loadDashboard);
  }

  MealPlanDashboard? get dashboard => _dashboard;
  MealPlanFilter get selectedFilter => _selectedFilter;
  bool get isLoading => _isLoading;
  bool get isWeatherLoading => _isWeatherLoading;
  String? get errorMessage => _errorMessage;
  String? get weatherErrorMessage => _weatherErrorMessage;

  List<MealPlanSection> get filteredSections {
    final sections = _dashboard?.sections ?? const <MealPlanSection>[];
    if (_selectedFilter == MealPlanFilter.all) return sections;
    final filterLabel = _selectedFilter.name.toLowerCase();
    return sections
        .where((section) => section.mealType.toLowerCase() == filterLabel)
        .toList();
  }

  int mealCountFor(MealPlanFilter filter) {
    final sections = _dashboard?.sections ?? const <MealPlanSection>[];
    if (filter == MealPlanFilter.all) {
      return sections.fold<int>(
        0,
        (count, section) => count + section.meals.length,
      );
    }

    return sections
        .where((section) => section.mealType.toLowerCase() == filter.name)
        .fold<int>(0, (count, section) => count + section.meals.length);
  }

  void selectFilter(MealPlanFilter filter) {
    if (_selectedFilter == filter) return;
    _selectedFilter = filter;
    _notifyIfActive();
  }

  Future<void> loadDashboard() async {
    _isLoading = _dashboard == null;
    _errorMessage = null;
    _notifyIfActive();

    final result = await _getDashboardUseCase.execute();
    if (_isDisposed) return;

    result.ifRight((dashboard) {
      _dashboard = dashboard;
      _isWeatherLoading = true;
    });
    result.ifLeft((failure) {
      _errorMessage = failure.message;
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

    final result = await _getWeatherUseCase.execute();
    if (_isDisposed) return;

    result.ifRight((weather) {
      _dashboard = currentDashboard.copyWith(weather: weather);
    });
    result.ifLeft((failure) {
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
