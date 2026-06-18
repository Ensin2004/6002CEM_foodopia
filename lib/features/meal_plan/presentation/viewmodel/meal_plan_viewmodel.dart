import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../../../core/services/weather_category_service.dart';
import '../../domain/entities/meal_plan_dashboard.dart';
import '../../domain/entities/meal_plan_inspiration_input.dart';
import '../../domain/usecases/get_meal_plan_dashboard_usecase.dart';
import '../../domain/usecases/get_meal_plan_inspiration_options_usecase.dart';
import '../../domain/usecases/get_meal_plan_preferences_usecase.dart';
import '../../domain/usecases/get_meal_plan_weather_usecase.dart';
import '../../domain/usecases/delete_meal_plan_usecase.dart';
import '../../domain/usecases/search_meal_plan_ingredients_usecase.dart';
import '../../domain/usecases/update_weekly_grocery_week_start_day_usecase.dart';

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

/// ViewModel for the Meal Plan feature.
/// Manages state for the main meal plan dashboard with three tabs.
class MealPlanViewModel extends ChangeNotifier {
  // =========================================================================
  // CONSTANTS
  // =========================================================================

  /// ID for the "All" filter option.
  static const String allFilterId = 'all';

  // =========================================================================
  // DEPENDENCIES
  // =========================================================================

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

  // =========================================================================
  // STATE
  // =========================================================================

  /// The meal plan dashboard data.
  MealPlanDashboard? _dashboard;

  /// Currently selected date.
  DateTime _selectedDate = DateTime.now();

  /// User preferences summary.
  MealPlanPreferenceSummary? _preferences;

  /// Selected filter ID for meal sections.
  String _selectedFilterId = allFilterId;

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

  // =========================================================================
  // CONSTRUCTOR
  // =========================================================================

  /// Creates a new MealPlanViewModel.
  MealPlanViewModel({
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
            updateWeeklyGroceryWeekStartDayUseCase {
    // Load the dashboard asynchronously after construction.
    Future.microtask(loadDashboard);
  }

  // =========================================================================
  // GETTERS
  // =========================================================================

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

  /// Selected ingredients.
  List<MealPlanInspirationIngredient> get selectedIngredients =>
      List.unmodifiable(_selectedIngredients);

  /// Ingredient search results.
  List<MealPlanInspirationIngredient> get ingredientSearchResults =>
      _ingredientSearchResults;

  /// Preference search results.
  List<MealPlanInspirationIngredient> get preferenceSearchResults =>
      _preferenceSearchResults;

  /// Whether inspiration options are loading.
  bool get isInspirationOptionsLoading => _isInspirationOptionsLoading;

  /// Whether ingredient search is in progress.
  bool get isIngredientSearching => _isIngredientSearching;

  /// Whether preference search is in progress.
  bool get isPreferenceSearching => _isPreferenceSearching;

  /// Error message from inspiration.
  String? get inspirationErrorMessage => _inspirationErrorMessage;

  /// Diet options.
  List<MealPlanPreferenceOption> get dietOptions => _dietOptions;

  /// Allergy options.
  List<MealPlanPreferenceOption> get allergyOptions => _allergyOptions;

  /// Dislike options.
  List<MealPlanPreferenceOption> get dislikeOptions => _dislikeOptions;

  /// Override diet.
  String get overrideDiet => _overrideDiet;

  /// Override allergies.
  List<String> get overrideAllergies => List.unmodifiable(_overrideAllergies);

  /// Override dislikes.
  List<String> get overrideDislikes => List.unmodifiable(_overrideDislikes);

  /// Selected ingredients label.
  String get selectedIngredientsLabel {
    if (_selectedIngredients.isEmpty) return 'Not added yet';
    return _selectedIngredients.map((item) => item.name).take(3).join(', ');
  }

  /// Effective preferences combining overrides with defaults.
  MealPlanPreferenceSummary get effectivePreferences {
    return MealPlanPreferenceSummary(
      diet: _overrideDiet,
      allergies: _overrideAllergies,
      dislikes: _overrideDislikes,
    );
  }

  /// Filtered meal sections based on selected filter.
  List<MealPlanSection> get filteredSections {
    // Get sections from dashboard.
    final sections = _dashboard?.sections ?? const <MealPlanSection>[];

    // Return all if "All" filter is selected.
    if (_selectedFilterId == allFilterId) return sections;

    // Filter sections by the selected filter ID.
    return sections
        .where((section) => _filterIdForSection(section) == _selectedFilterId)
        .toList();
  }

  /// Filter options for meal sections.
  List<MealPlanFilterOption> get filterOptions {
    // Get sections from dashboard.
    final sections = _dashboard?.sections ?? const <MealPlanSection>[];

    // Calculate total meal count.
    final totalCount = sections.fold<int>(
      0,
          (count, section) => count + section.meals.length,
    );

    // Build filter options.
    return [
      // "All" option.
      MealPlanFilterOption(id: allFilterId, label: 'All', count: totalCount),

      // Section options.
      ...sections.map(
            (section) => MealPlanFilterOption(
          id: _filterIdForSection(section),
          label: section.mealType,
          count: section.meals.length,
        ),
      ),
    ];
  }

  /// Filtered grocery lists based on tab and search query.
  List<GroceryListSummary> get filteredGroceryLists {
    // Get lists from dashboard.
    final lists = _dashboard?.groceryLists ?? const <GroceryListSummary>[];

    // Determine status filter.
    final status = _selectedGroceryListTab == GroceryListTabFilter.active
        ? GroceryListStatus.active
        : GroceryListStatus.past;

    // Get search query.
    final query = _grocerySearchQuery.trim().toLowerCase();

    // Filter lists.
    return lists.where((list) {
      // Filter by status.
      if (list.status != status) return false;

      // Filter by search query.
      if (query.isEmpty) return true;

      // Build searchable text.
      final dateText = '${list.startDate} ${list.endDate}'.toLowerCase();
      final categoryText = list.categories.join(' ').toLowerCase();

      // Check if query matches.
      return list.title.toLowerCase().contains(query) ||
          categoryText.contains(query) ||
          dateText.contains(query) ||
          list.weekStartDay.toLowerCase().contains(query);
    }).toList();
  }

  /// Current weekly grocery list.
  GroceryListSummary? get currentWeeklyGroceryList {
    // Get lists from dashboard.
    final lists = _dashboard?.groceryLists ?? const <GroceryListSummary>[];

    // Find active weekly list.
    for (final list in lists) {
      if (list.isWeekly && list.status == GroceryListStatus.active) {
        return list;
      }
    }
    return null;
  }

  /// Filtered custom grocery lists.
  List<GroceryListSummary> get filteredCustomGroceryLists {
    return filteredGroceryLists.where((list) => !list.isWeekly).toList();
  }

  /// Filtered weekly history.
  List<GroceryListSummary> get filteredWeeklyHistory {
    return filteredGroceryLists.where((list) => list.isWeekly).toList();
  }

  // =========================================================================
  // GROCERY LIST TAB
  // =========================================================================

  /// Selects a grocery list tab.
  void selectGroceryListTab(GroceryListTabFilter tab) {
    if (_selectedGroceryListTab == tab) return;
    _selectedGroceryListTab = tab;
    _notifyIfActive();
  }

  /// Updates the grocery search query.
  void updateGrocerySearchQuery(String query) {
    _grocerySearchQuery = query;
    _notifyIfActive();
  }

  /// Clears the grocery search query.
  void clearGrocerySearchQuery() {
    if (_grocerySearchQuery.isEmpty) return;
    _grocerySearchQuery = '';
    _notifyIfActive();
  }

  /// Updates the weekly grocery week start day.
  Future<void> updateWeeklyGroceryWeekStartDay(String weekStartDay) async {
    // Clear any previous error.
    _groceryActionErrorMessage = null;
    _notifyIfActive();

    // Execute the use case.
    final result = await _updateWeeklyGroceryWeekStartDayUseCase.execute(
      userId: userId,
      weekStartDay: weekStartDay,
    );

    // Check if disposed.
    if (_isDisposed) return;

    // Handle result.
    result.ifLeft((failure) {
      _groceryActionErrorMessage = failure.message;
    });
    result.ifRight((_) {
      _groceryActionErrorMessage = null;
    });

    // Reload the dashboard.
    await loadDashboard();
  }

  // =========================================================================
  // MEAL FILTER
  // =========================================================================

  /// Selects a meal filter.
  void selectFilter(String filterId) {
    if (_selectedFilterId == filterId) return;
    _selectedFilterId = filterId;
    _notifyIfActive();
  }

  // =========================================================================
  // MEAL PLAN CRUD
  // =========================================================================

  /// Deletes a meal plan.
  Future<bool> deleteMealPlan(String mealPlanId) async {
    // Validate the ID.
    final trimmedId = mealPlanId.trim();
    if (trimmedId.isEmpty) {
      _mealActionErrorMessage = 'Meal plan is missing.';
      _notifyIfActive();
      return false;
    }

    // Clear any previous error.
    _mealActionErrorMessage = null;
    _notifyIfActive();

    // Execute the use case.
    final result = await _deleteMealPlanUseCase.execute(
      userId: userId,
      mealPlanId: trimmedId,
    );

    // Check if disposed.
    if (_isDisposed) return false;

    // Handle result.
    var deleted = false;
    result.ifRight((_) => deleted = true);
    result.ifLeft((failure) => _mealActionErrorMessage = failure.message);

    _notifyIfActive();

    // Update local state if deleted.
    if (deleted) {
      _removeMealFromDashboard(trimmedId);
      unawaited(loadDashboard());
    }

    return deleted;
  }

  // =========================================================================
  // DASHBOARD
  // =========================================================================

  /// Loads the meal plan dashboard.
  Future<void> loadDashboard() async {
    // Set loading state.
    _isLoading = _dashboard == null;
    _errorMessage = null;
    _notifyIfActive();

    // Execute the use case.
    final result = await _getDashboardUseCase.execute(
      userId: userId,
      selectedDate: _selectedDate,
    );

    // Check if disposed.
    if (_isDisposed) return;

    // Handle success.
    result.ifRight((dashboard) {
      _dashboard = dashboard;
      _normalizeSelectedFilter();
      _isWeatherLoading = true;
    });

    // Handle failure.
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    // Reset loading state.
    _isLoading = false;
    _notifyIfActive();

    // Load additional data.
    await refreshWeather();
    await loadPreferences();
    await loadInspirationInputs();
  }

  /// Selects a date and reloads the dashboard.
  Future<void> selectDate(DateTime date) async {
    _selectedDate = DateTime(date.year, date.month, date.day);
    await loadDashboard();
  }

  // =========================================================================
  // PREFERENCES
  // =========================================================================

  /// Loads user preferences.
  Future<void> loadPreferences() async {
    // Set loading state.
    _isPreferencesLoading = true;
    _preferencesErrorMessage = null;
    _notifyIfActive();

    // Execute the use case.
    final result = await _getPreferencesUseCase.execute(userId);

    // Check if disposed.
    if (_isDisposed) return;

    // Handle success.
    result.ifRight((preferences) {
      _preferences = preferences;
      _overrideDiet = preferences.diet.trim().isEmpty
          ? 'No specific diet'
          : preferences.diet;
      _replaceValues(_overrideAllergies, preferences.allergies);
      _replaceValues(_overrideDislikes, preferences.dislikes);
    });

    // Handle failure.
    result.ifLeft((failure) {
      _preferencesErrorMessage = failure.message;
    });

    // Reset loading state.
    _isPreferencesLoading = false;
    _notifyIfActive();
  }

  // =========================================================================
  // WEATHER
  // =========================================================================

  /// Refreshes the weather data.
  Future<void> refreshWeather() async {
    // Get the current dashboard.
    final currentDashboard = _dashboard;
    if (currentDashboard == null) return;

    // Set loading state.
    _isWeatherLoading = true;
    _weatherErrorMessage = null;
    _notifyIfActive();

    // Execute the use case.
    final result = await _getWeatherUseCase.execute(
      currentDashboard.selectedDate,
    );

    // Check if disposed.
    if (_isDisposed) return;

    // Handle success.
    result.ifRight((weather) {
      _dashboard = currentDashboard.copyWith(weather: weather);
      _selectedWeatherCategoryId = WeatherCategoryService.matchCondition(
        weather.condition,
        weather.currentTemp,
      ).id;
    });

    // Handle failure.
    result.ifLeft((failure) {
      _weatherErrorMessage = failure.message;
    });

    // Reset loading state.
    _isWeatherLoading = false;
    _notifyIfActive();
  }

  /// Selects a weather category.
  void selectWeatherCategory(String id) {
    _selectedWeatherCategoryId = id;
    _notifyIfActive();
  }

  // =========================================================================
  // INSPIRATION INPUTS
  // =========================================================================

  /// Loads inspiration input options.
  Future<void> loadInspirationInputs() async {
    // Set loading state.
    _isInspirationOptionsLoading = true;
    _inspirationErrorMessage = null;
    _notifyIfActive();

    // Fetch all options in parallel.
    final dietOptionsResult = await _getInspirationOptionsUseCase.execute(
      'meal_preferences',
    );
    final allergyOptionsResult = await _getInspirationOptionsUseCase.execute(
      'allergies',
    );
    final dislikeOptionsResult = await _getInspirationOptionsUseCase.execute(
      'dislikes',
    );

    // Check if disposed.
    if (_isDisposed) return;

    // Handle results.
    dietOptionsResult.ifRight((items) {
      _dietOptions = _withRequiredOption(items, 'No specific diet');
    });
    allergyOptionsResult.ifRight((items) {
      _allergyOptions = _withRequiredOption(items, 'None');
    });
    dislikeOptionsResult.ifRight((items) {
      _dislikeOptions = _withRequiredOption(items, 'None');
    });

    // Reset loading state.
    _isInspirationOptionsLoading = false;
    _notifyIfActive();
  }

  /// Searches for ingredients.
  Future<void> searchIngredients(String query) async {
    // Trim the query.
    final trimmed = query.trim();

    // Clear results if query is too short.
    if (trimmed.length < 2) {
      _ingredientSearchResults = const [];
      _isIngredientSearching = false;
      _notifyIfActive();
      return;
    }

    // Set searching state.
    _isIngredientSearching = true;
    _notifyIfActive();

    // Execute the search.
    final result = await _searchIngredientsUseCase.execute(trimmed);

    // Check if disposed.
    if (_isDisposed) return;

    // Handle result.
    result.ifRight((items) => _ingredientSearchResults = items);
    result.ifLeft((failure) => _inspirationErrorMessage = failure.message);

    // Reset searching state.
    _isIngredientSearching = false;
    _notifyIfActive();
  }

  /// Searches for preference foods.
  Future<void> searchPreferenceFoods(String query) async {
    // Trim the query.
    final trimmed = query.trim();

    // Clear results if query is too short.
    if (trimmed.length < 2) {
      _preferenceSearchResults = const [];
      _isPreferenceSearching = false;
      _notifyIfActive();
      return;
    }

    // Set searching state.
    _isPreferenceSearching = true;
    _notifyIfActive();

    // Execute the search.
    final result = await _searchIngredientsUseCase.execute(trimmed);

    // Check if disposed.
    if (_isDisposed) return;

    // Handle result.
    result.ifRight((items) => _preferenceSearchResults = items);
    result.ifLeft((failure) => _inspirationErrorMessage = failure.message);

    // Reset searching state.
    _isPreferenceSearching = false;
    _notifyIfActive();
  }

  /// Toggles an ingredient selection.
  void toggleIngredient(MealPlanInspirationIngredient ingredient) {
    // Find the index of the ingredient.
    final index = _selectedIngredients.indexWhere((item) {
      return item.name.toLowerCase() == ingredient.name.toLowerCase();
    });

    // Toggle the ingredient.
    if (index >= 0) {
      _selectedIngredients.removeAt(index);
    } else {
      _selectedIngredients.add(ingredient);
    }

    _notifyIfActive();
  }

  /// Adds a custom ingredient.
  void addCustomIngredient(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    // Create and toggle the custom ingredient.
    toggleIngredient(
      MealPlanInspirationIngredient(
        id: trimmed.toLowerCase().replaceAll(RegExp(r'\s+'), '_'),
        name: trimmed,
        isCustom: true,
      ),
    );
  }

  /// Checks if an ingredient is selected.
  bool isIngredientSelected(String name) {
    return _selectedIngredients.any(
          (item) => item.name.toLowerCase() == name.toLowerCase(),
    );
  }

  // =========================================================================
  // PREFERENCE OVERRIDES
  // =========================================================================

  /// Selects an override diet.
  void selectOverrideDiet(String value) {
    _overrideDiet = value;
    _notifyIfActive();
  }

  /// Toggles an override allergy.
  void toggleOverrideAllergy(String value) {
    _toggleValue(_overrideAllergies, value);
    _notifyIfActive();
  }

  /// Toggles an override dislike.
  void toggleOverrideDislike(String value) {
    _toggleValue(_overrideDislikes, value);
    _notifyIfActive();
  }

  /// Adds a custom override allergy.
  void addCustomOverrideAllergy(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    // Remove "None" if present.
    _overrideAllergies.remove('None');

    // Add the custom value if not present.
    if (!_overrideAllergies.contains(trimmed)) {
      _overrideAllergies.add(trimmed);
    }

    _notifyIfActive();
  }

  /// Adds a custom override dislike.
  void addCustomOverrideDislike(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    // Remove "None" if present.
    _overrideDislikes.remove('None');

    // Add the custom value if not present.
    if (!_overrideDislikes.contains(trimmed)) {
      _overrideDislikes.add(trimmed);
    }

    _notifyIfActive();
  }

  // =========================================================================
  // PRIVATE HELPERS
  // =========================================================================

  /// Replaces values in a list with a source list.
  void _replaceValues(List<String> target, List<String> source) {
    target
      ..clear()
      ..addAll(source);
  }

  /// Toggles a value in a list.
  void _toggleValue(List<String> values, String value) {
    // Handle "None" as a special case.
    if (value == 'None') {
      if (values.contains(value)) {
        values.clear();
      } else {
        values
          ..clear()
          ..add(value);
      }
      return;
    }

    // Remove "None" if present.
    values.remove('None');

    // Toggle the value.
    if (values.contains(value)) {
      values.remove(value);
    } else {
      values.add(value);
    }
  }

  /// Ensures a required option is present in a list.
  List<MealPlanPreferenceOption> _withRequiredOption(
      List<MealPlanPreferenceOption> source,
      String name,
      ) {
    // Check if the option already exists.
    final hasOption = source.any(
          (item) => item.name.toLowerCase() == name.toLowerCase(),
    );

    // Return the list unchanged if the option exists.
    if (hasOption) return source;

    // Add the required option.
    return [
      MealPlanPreferenceOption(
        id: name.toLowerCase().replaceAll(' ', '_'),
        name: name,
      ),
      ...source,
    ];
  }

  /// Returns a filter ID for a section.
  String _filterIdForSection(MealPlanSection section) {
    // Use category ID if available.
    final categoryId = section.mealCategoryId.trim();
    if (categoryId.isNotEmpty) return categoryId;

    // Otherwise use the meal type.
    return section.mealType.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      '_',
    );
  }

  /// Normalizes the selected filter.
  void _normalizeSelectedFilter() {
    // Skip if "All" filter is selected.
    if (_selectedFilterId == allFilterId) return;

    // Get sections from dashboard.
    final sections = _dashboard?.sections ?? const <MealPlanSection>[];

    // Check if the selected filter exists.
    final exists = sections.any(
          (section) => _filterIdForSection(section) == _selectedFilterId,
    );

    // Reset to "All" if the filter doesn't exist.
    if (!exists) _selectedFilterId = allFilterId;
  }

  /// Removes a meal from the dashboard.
  void _removeMealFromDashboard(String mealPlanId) {
    // Get the current dashboard.
    final current = _dashboard;
    if (current == null) return;

    // Remove the meal from sections.
    var removed = false;
    final sections = current.sections.map((section) {
      final meals = section.meals.where((meal) {
        final shouldKeep = meal.id != mealPlanId;
        if (!shouldKeep) removed = true;
        return shouldKeep;
      }).toList();
      return MealPlanSection(
        mealType: section.mealType,
        mealCategoryId: section.mealCategoryId,
        meals: meals,
      );
    }).toList();

    // Return if no meal was removed.
    if (!removed) return;

    // Check if the selected date still has meals.
    final hasMealsForSelectedDate = sections.any(
          (section) => section.meals.isNotEmpty,
    );

    // Update month days.
    final monthDays = current.monthDays.map((day) {
      if (!_sameDay(day.date, current.selectedDate)) return day;
      return MealPlanDay(
        date: day.date,
        isCurrentMonth: day.isCurrentMonth,
        hasMeals: hasMealsForSelectedDate,
      );
    }).toList();

    // Update the dashboard.
    _dashboard = current.copyWith(
      sections: sections,
      monthDays: monthDays,
      summary: _decrementSummary(current.summary, current.selectedDate),
    );

    // Normalize the filter.
    _normalizeSelectedFilter();
    _notifyIfActive();
  }

  /// Decrements a summary count for a date.
  MealPlanSummary _decrementSummary(MealPlanSummary summary, DateTime date) {
    // Normalize the date.
    final day = DateTime(date.year, date.month, date.day);

    // Get today's date.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Decrement the appropriate count.
    if (day.isBefore(today)) {
      return MealPlanSummary(
        pastCount: (summary.pastCount - 1).clamp(0, 1 << 31).toInt(),
        todayCount: summary.todayCount,
        futureCount: summary.futureCount,
      );
    }
    if (day.isAfter(today)) {
      return MealPlanSummary(
        pastCount: summary.pastCount,
        todayCount: summary.todayCount,
        futureCount: (summary.futureCount - 1).clamp(0, 1 << 31).toInt(),
      );
    }
    return MealPlanSummary(
      pastCount: summary.pastCount,
      todayCount: (summary.todayCount - 1).clamp(0, 1 << 31).toInt(),
      futureCount: summary.futureCount,
    );
  }

  /// Checks if two dates are the same day.
  bool _sameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

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