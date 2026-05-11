import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/meal_plan_dashboard.dart';
import '../../domain/usecases/get_meal_plan_dashboard_usecase.dart';
import '../../domain/usecases/get_meal_plan_preferences_usecase.dart';
import '../../domain/usecases/get_meal_plan_weather_usecase.dart';

enum MealPlanFilter { all, breakfast, lunch, dinner }

enum GroceryListTabFilter { active, past }

class MealPlanViewModel extends ChangeNotifier {
  final GetMealPlanDashboardUseCase _getDashboardUseCase;
  final GetMealPlanWeatherUseCase _getWeatherUseCase;
  final GetMealPlanPreferencesUseCase _getPreferencesUseCase;
  final String userId;

  MealPlanDashboard? _dashboard;
  MealPlanPreferenceSummary? _preferences;
  MealPlanFilter _selectedFilter = MealPlanFilter.all;
  GroceryListTabFilter _selectedGroceryListTab = GroceryListTabFilter.active;
  bool _isLoading = true;
  bool _isWeatherLoading = false;
  bool _isPreferencesLoading = false;
  bool _isDisposed = false;
  String? _errorMessage;
  String? _weatherErrorMessage;
  String? _preferencesErrorMessage;

  MealPlanViewModel({
    required this.userId,
    required GetMealPlanDashboardUseCase getDashboardUseCase,
    required GetMealPlanWeatherUseCase getWeatherUseCase,
    required GetMealPlanPreferencesUseCase getPreferencesUseCase,
  }) : _getDashboardUseCase = getDashboardUseCase,
       _getWeatherUseCase = getWeatherUseCase,
       _getPreferencesUseCase = getPreferencesUseCase {
    Future.microtask(loadDashboard);
  }

  MealPlanDashboard? get dashboard => _dashboard;
  MealPlanPreferenceSummary? get preferences => _preferences;
  MealPlanFilter get selectedFilter => _selectedFilter;
  GroceryListTabFilter get selectedGroceryListTab => _selectedGroceryListTab;
  bool get isLoading => _isLoading;
  bool get isWeatherLoading => _isWeatherLoading;
  bool get isPreferencesLoading => _isPreferencesLoading;
  String? get errorMessage => _errorMessage;
  String? get weatherErrorMessage => _weatherErrorMessage;
  String? get preferencesErrorMessage => _preferencesErrorMessage;

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

  List<GroceryListSummary> get filteredGroceryLists {
    final lists = _dashboard?.groceryLists ?? const <GroceryListSummary>[];
    final status = _selectedGroceryListTab == GroceryListTabFilter.active
        ? GroceryListStatus.active
        : GroceryListStatus.past;
    return lists.where((list) => list.status == status).toList();
  }

  void selectGroceryListTab(GroceryListTabFilter tab) {
    if (_selectedGroceryListTab == tab) return;
    _selectedGroceryListTab = tab;
    _notifyIfActive();
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
    await loadPreferences();
  }

  Future<void> loadPreferences() async {
    _isPreferencesLoading = true;
    _preferencesErrorMessage = null;
    _notifyIfActive();

    final result = await _getPreferencesUseCase.execute(userId);
    if (_isDisposed) return;

    result.ifRight((preferences) {
      _preferences = preferences;
    });
    result.ifLeft((failure) {
      _preferencesErrorMessage = failure.message;
    });

    _isPreferencesLoading = false;
    _notifyIfActive();
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
