import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../../../core/services/weather_category_service.dart';
import '../../domain/entities/meal_plan_dashboard.dart';
import '../../domain/entities/meal_plan_inspiration_input.dart';
import '../../domain/usecases/delete_meal_plan_usecase.dart';
import '../../domain/usecases/get_meal_plan_dashboard_usecase.dart';
import '../../domain/usecases/get_meal_plan_inspiration_options_usecase.dart';
import '../../domain/usecases/get_meal_plan_preferences_usecase.dart';
import '../../domain/usecases/get_meal_plan_weather_usecase.dart';
import '../../domain/usecases/search_meal_plan_ingredients_usecase.dart';
import '../../domain/usecases/update_weekly_grocery_week_start_day_usecase.dart';

part 'meal_plan/meal_plan_dashboard_viewmodel_mixin.dart';
part 'meal_plan/meal_plan_grocery_viewmodel_mixin.dart';
part 'meal_plan/meal_plan_inspiration_viewmodel_mixin.dart';
part 'meal_plan/meal_plan_viewmodel_helpers.dart';

const String _allMealPlanFilterId = 'all';

/// Filter for grocery list tabs.
enum GroceryListTabFilter {
  /// Show active grocery lists.
  active,

  /// Show past grocery lists.
  past,
}

/// Filter option for meal plan sections.
class MealPlanFilterOption {
  /// Unique identifier for the filter.
  final String id;

  /// Display label for the filter.
  final String label;

  /// Count of items matching this filter.
  final int count;

  /// Creates a new meal plan filter option.
  const MealPlanFilterOption({
    required this.id,
    required this.label,
    required this.count,
  });
}

/// ViewModel for the Meal Plan dashboard.
class MealPlanViewModel extends _MealPlanViewModelBase
    with
        _MealPlanViewModelHelpers,
        _MealPlanInspirationViewModelMixin,
        _MealPlanDashboardViewModelMixin,
        _MealPlanGroceryViewModelMixin {
  /// ID for the "All" filter option.
  static const String allFilterId = _allMealPlanFilterId;

  /// Creates a new MealPlanViewModel.
  MealPlanViewModel({
    required super.userId,
    required super.getDashboardUseCase,
    required super.getWeatherUseCase,
    required super.getPreferencesUseCase,
    required super.searchIngredientsUseCase,
    required super.getInspirationOptionsUseCase,
    required super.deleteMealPlanUseCase,
    required super.updateWeeklyGroceryWeekStartDayUseCase,
  }) {
    // Initial dashboard load starts after provider construction.
    Future.microtask(loadDashboard);
  }
}

/// Shared state and dependencies for meal plan viewmodel mixins.
abstract class _MealPlanViewModelBase extends ChangeNotifier {
  /// Use case for fetching the dashboard.
  final GetMealPlanDashboardUseCase _getDashboardUseCase;

  /// Use case for fetching weather data.
  final GetMealPlanWeatherUseCase _getWeatherUseCase;

  /// Use case for fetching user preferences.
  final GetMealPlanPreferencesUseCase _getPreferencesUseCase;

  /// Use case for searching ingredients.
  final SearchMealPlanIngredientsUseCase _searchIngredientsUseCase;

  /// Use case for fetching inspiration options.
  final GetMealPlanInspirationOptionsUseCase _getInspirationOptionsUseCase;

  /// Use case for deleting a meal plan.
  final DeleteMealPlanUseCase _deleteMealPlanUseCase;

  /// Use case for updating weekly grocery week start day.
  final UpdateWeeklyGroceryWeekStartDayUseCase
  _updateWeeklyGroceryWeekStartDayUseCase;

  /// User ID of the current user.
  final String userId;

  /// The meal plan dashboard data.
  MealPlanDashboard? _dashboard;

  /// Currently selected date.
  DateTime _selectedDate = DateTime.now();

  /// User preferences summary.
  MealPlanPreferenceSummary? _preferences;

  /// Selected filter ID for meal sections.
  String _selectedFilterId = _allMealPlanFilterId;

  /// Selected grocery list tab.
  GroceryListTabFilter _selectedGroceryListTab = GroceryListTabFilter.active;

  /// Whether data is loading.
  bool _isLoading = true;

  /// Whether weather data is loading.
  bool _isWeatherLoading = false;

  /// Whether preferences are loading.
  bool _isPreferencesLoading = false;

  /// Whether the ViewModel has been disposed.
  bool _isDisposed = false;

  /// Error message from loading.
  String? _errorMessage;

  /// Error message from weather.
  String? _weatherErrorMessage;

  /// Error message from preferences.
  String? _preferencesErrorMessage;

  /// Error message from grocery actions.
  String? _groceryActionErrorMessage;

  /// Error message from meal actions.
  String? _mealActionErrorMessage;

  /// Grocery search query.
  String _grocerySearchQuery = '';

  /// Selected weather category ID.
  String _selectedWeatherCategoryId =
      WeatherCategoryService.categories.first.id;

  /// Selected ingredients for inspiration.
  final List<MealPlanInspirationIngredient> _selectedIngredients = [];

  /// Ingredient search results.
  List<MealPlanInspirationIngredient> _ingredientSearchResults = const [];

  /// Preference search results.
  List<MealPlanInspirationIngredient> _preferenceSearchResults = const [];

  /// Whether inspiration options are loading.
  bool _isInspirationOptionsLoading = false;

  /// Whether ingredient search is in progress.
  bool _isIngredientSearching = false;

  /// Whether preference search is in progress.
  bool _isPreferenceSearching = false;

  /// Error message from inspiration.
  String? _inspirationErrorMessage;

  /// Diet options.
  List<MealPlanPreferenceOption> _dietOptions = const [];

  /// Allergy options.
  List<MealPlanPreferenceOption> _allergyOptions = const [];

  /// Dislike options.
  List<MealPlanPreferenceOption> _dislikeOptions = const [];

  /// Override diet value.
  String _overrideDiet = 'No specific diet';

  /// Override allergies.
  final List<String> _overrideAllergies = [];

  /// Override dislikes.
  final List<String> _overrideDislikes = [];

  /// Creates shared meal plan state.
  _MealPlanViewModelBase({
    required this.userId,
    required GetMealPlanDashboardUseCase getDashboardUseCase,
    required GetMealPlanWeatherUseCase getWeatherUseCase,
    required GetMealPlanPreferencesUseCase getPreferencesUseCase,
    required SearchMealPlanIngredientsUseCase searchIngredientsUseCase,
    required GetMealPlanInspirationOptionsUseCase getInspirationOptionsUseCase,
    required DeleteMealPlanUseCase deleteMealPlanUseCase,
    required UpdateWeeklyGroceryWeekStartDayUseCase
    updateWeeklyGroceryWeekStartDayUseCase,
  }) : _getDashboardUseCase = getDashboardUseCase,
       _getWeatherUseCase = getWeatherUseCase,
       _getPreferencesUseCase = getPreferencesUseCase,
       _searchIngredientsUseCase = searchIngredientsUseCase,
       _getInspirationOptionsUseCase = getInspirationOptionsUseCase,
       _deleteMealPlanUseCase = deleteMealPlanUseCase,
       _updateWeeklyGroceryWeekStartDayUseCase =
           updateWeeklyGroceryWeekStartDayUseCase;

  /// The meal plan dashboard.
  MealPlanDashboard? get dashboard => _dashboard;

  /// User preferences.
  MealPlanPreferenceSummary? get preferences => _preferences;

  /// Selected filter ID.
  String get selectedFilterId => _selectedFilterId;

  /// Selected grocery list tab.
  GroceryListTabFilter get selectedGroceryListTab => _selectedGroceryListTab;

  /// Whether data is loading.
  bool get isLoading => _isLoading;

  /// Whether weather data is loading.
  bool get isWeatherLoading => _isWeatherLoading;

  /// Whether preferences are loading.
  bool get isPreferencesLoading => _isPreferencesLoading;

  /// Error message from loading.
  String? get errorMessage => _errorMessage;

  /// Error message from weather.
  String? get weatherErrorMessage => _weatherErrorMessage;

  /// Error message from preferences.
  String? get preferencesErrorMessage => _preferencesErrorMessage;

  /// Error message from grocery actions.
  String? get groceryActionErrorMessage => _groceryActionErrorMessage;

  /// Error message from meal actions.
  String? get mealActionErrorMessage => _mealActionErrorMessage;

  /// Grocery search query.
  String get grocerySearchQuery => _grocerySearchQuery;

  /// Weather categories.
  List<WeatherCategory> get weatherCategories =>
      WeatherCategoryService.categories;

  /// Selected weather category ID.
  String get selectedWeatherCategoryId => _selectedWeatherCategoryId;

  /// Selected weather category.
  WeatherCategory get selectedWeatherCategory {
    return WeatherCategoryService.byId(_selectedWeatherCategoryId);
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
