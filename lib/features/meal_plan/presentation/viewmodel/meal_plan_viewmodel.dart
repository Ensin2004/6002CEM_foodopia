import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../../../core/services/weather_category_service.dart';
import '../../domain/entities/meal_plan_dashboard.dart';
import '../../domain/entities/meal_plan_inspiration_input.dart';
import '../../domain/usecases/get_meal_plan_dashboard_usecase.dart';
import '../../domain/usecases/get_meal_plan_inspiration_options_usecase.dart';
import '../../domain/usecases/get_meal_plan_preferences_usecase.dart';
import '../../domain/usecases/get_meal_plan_weather_usecase.dart';
import '../../domain/usecases/search_meal_plan_ingredients_usecase.dart';

enum GroceryListTabFilter { active, past }

class MealPlanFilterOption {
  final String id;
  final String label;
  final int count;

  const MealPlanFilterOption({
    required this.id,
    required this.label,
    required this.count,
  });
}

class MealPlanViewModel extends ChangeNotifier {
  static const String allFilterId = 'all';

  final GetMealPlanDashboardUseCase _getDashboardUseCase;
  final GetMealPlanWeatherUseCase _getWeatherUseCase;
  final GetMealPlanPreferencesUseCase _getPreferencesUseCase;
  final SearchMealPlanIngredientsUseCase _searchIngredientsUseCase;
  final GetMealPlanInspirationOptionsUseCase _getInspirationOptionsUseCase;
  final String userId;

  MealPlanDashboard? _dashboard;
  DateTime _selectedDate = DateTime.now();
  MealPlanPreferenceSummary? _preferences;
  String _selectedFilterId = allFilterId;
  GroceryListTabFilter _selectedGroceryListTab = GroceryListTabFilter.active;
  bool _isLoading = true;
  bool _isWeatherLoading = false;
  bool _isPreferencesLoading = false;
  bool _isDisposed = false;
  String? _errorMessage;
  String? _weatherErrorMessage;
  String? _preferencesErrorMessage;
  String _selectedWeatherCategoryId =
      WeatherCategoryService.categories.first.id;
  final List<MealPlanInspirationIngredient> _selectedIngredients = [];
  List<MealPlanInspirationIngredient> _ingredientSearchResults = const [];
  List<MealPlanInspirationIngredient> _preferenceSearchResults = const [];
  bool _isInspirationOptionsLoading = false;
  bool _isIngredientSearching = false;
  bool _isPreferenceSearching = false;
  String? _inspirationErrorMessage;
  List<MealPlanPreferenceOption> _dietOptions = const [];
  List<MealPlanPreferenceOption> _allergyOptions = const [];
  List<MealPlanPreferenceOption> _dislikeOptions = const [];
  String _overrideDiet = 'No specific diet';
  final List<String> _overrideAllergies = [];
  final List<String> _overrideDislikes = [];

  MealPlanViewModel({
    required this.userId,
    required GetMealPlanDashboardUseCase getDashboardUseCase,
    required GetMealPlanWeatherUseCase getWeatherUseCase,
    required GetMealPlanPreferencesUseCase getPreferencesUseCase,
    required SearchMealPlanIngredientsUseCase searchIngredientsUseCase,
    required GetMealPlanInspirationOptionsUseCase getInspirationOptionsUseCase,
  }) : _getDashboardUseCase = getDashboardUseCase,
       _getWeatherUseCase = getWeatherUseCase,
       _getPreferencesUseCase = getPreferencesUseCase,
       _searchIngredientsUseCase = searchIngredientsUseCase,
       _getInspirationOptionsUseCase = getInspirationOptionsUseCase {
    Future.microtask(loadDashboard);
  }

  MealPlanDashboard? get dashboard => _dashboard;
  MealPlanPreferenceSummary? get preferences => _preferences;
  String get selectedFilterId => _selectedFilterId;
  GroceryListTabFilter get selectedGroceryListTab => _selectedGroceryListTab;
  bool get isLoading => _isLoading;
  bool get isWeatherLoading => _isWeatherLoading;
  bool get isPreferencesLoading => _isPreferencesLoading;
  String? get errorMessage => _errorMessage;
  String? get weatherErrorMessage => _weatherErrorMessage;
  String? get preferencesErrorMessage => _preferencesErrorMessage;
  List<WeatherCategory> get weatherCategories =>
      WeatherCategoryService.categories;
  String get selectedWeatherCategoryId => _selectedWeatherCategoryId;
  WeatherCategory get selectedWeatherCategory {
    return WeatherCategoryService.byId(_selectedWeatherCategoryId);
  }

  List<MealPlanInspirationIngredient> get selectedIngredients =>
      List.unmodifiable(_selectedIngredients);
  List<MealPlanInspirationIngredient> get ingredientSearchResults =>
      _ingredientSearchResults;
  List<MealPlanInspirationIngredient> get preferenceSearchResults =>
      _preferenceSearchResults;
  bool get isInspirationOptionsLoading => _isInspirationOptionsLoading;
  bool get isIngredientSearching => _isIngredientSearching;
  bool get isPreferenceSearching => _isPreferenceSearching;
  String? get inspirationErrorMessage => _inspirationErrorMessage;
  List<MealPlanPreferenceOption> get dietOptions => _dietOptions;
  List<MealPlanPreferenceOption> get allergyOptions => _allergyOptions;
  List<MealPlanPreferenceOption> get dislikeOptions => _dislikeOptions;
  String get overrideDiet => _overrideDiet;
  List<String> get overrideAllergies => List.unmodifiable(_overrideAllergies);
  List<String> get overrideDislikes => List.unmodifiable(_overrideDislikes);
  String get selectedIngredientsLabel {
    if (_selectedIngredients.isEmpty) return 'Not added yet';
    return _selectedIngredients.map((item) => item.name).take(3).join(', ');
  }

  MealPlanPreferenceSummary get effectivePreferences {
    return MealPlanPreferenceSummary(
      diet: _overrideDiet,
      allergies: _overrideAllergies,
      dislikes: _overrideDislikes,
    );
  }

  List<MealPlanSection> get filteredSections {
    final sections = _dashboard?.sections ?? const <MealPlanSection>[];
    if (_selectedFilterId == allFilterId) return sections;
    return sections
        .where((section) => _filterIdForSection(section) == _selectedFilterId)
        .toList();
  }

  List<MealPlanFilterOption> get filterOptions {
    final sections = _dashboard?.sections ?? const <MealPlanSection>[];
    final totalCount = sections.fold<int>(
      0,
      (count, section) => count + section.meals.length,
    );

    return [
      MealPlanFilterOption(id: allFilterId, label: 'All', count: totalCount),
      ...sections.map(
        (section) => MealPlanFilterOption(
          id: _filterIdForSection(section),
          label: section.mealType,
          count: section.meals.length,
        ),
      ),
    ];
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

  void selectFilter(String filterId) {
    if (_selectedFilterId == filterId) return;
    _selectedFilterId = filterId;
    _notifyIfActive();
  }

  Future<void> loadDashboard() async {
    _isLoading = _dashboard == null;
    _errorMessage = null;
    _notifyIfActive();

    final result = await _getDashboardUseCase.execute(
      userId: userId,
      selectedDate: _selectedDate,
    );
    if (_isDisposed) return;

    result.ifRight((dashboard) {
      _dashboard = dashboard;
      _normalizeSelectedFilter();
      _isWeatherLoading = true;
    });
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    _isLoading = false;
    _notifyIfActive();

    await refreshWeather();
    await loadPreferences();
    await loadInspirationInputs();
  }

  Future<void> selectDate(DateTime date) async {
    _selectedDate = DateTime(date.year, date.month, date.day);
    await loadDashboard();
  }

  Future<void> loadPreferences() async {
    _isPreferencesLoading = true;
    _preferencesErrorMessage = null;
    _notifyIfActive();

    final result = await _getPreferencesUseCase.execute(userId);
    if (_isDisposed) return;

    result.ifRight((preferences) {
      _preferences = preferences;
      _overrideDiet = preferences.diet.trim().isEmpty
          ? 'No specific diet'
          : preferences.diet;
      _replaceValues(_overrideAllergies, preferences.allergies);
      _replaceValues(_overrideDislikes, preferences.dislikes);
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

    final result = await _getWeatherUseCase.execute(
      currentDashboard.selectedDate,
    );
    if (_isDisposed) return;

    result.ifRight((weather) {
      _dashboard = currentDashboard.copyWith(weather: weather);
      _selectedWeatherCategoryId = WeatherCategoryService.matchCondition(
        weather.condition,
        weather.currentTemp,
      ).id;
    });
    result.ifLeft((failure) {
      _weatherErrorMessage = failure.message;
    });

    _isWeatherLoading = false;
    _notifyIfActive();
  }

  Future<void> loadInspirationInputs() async {
    _isInspirationOptionsLoading = true;
    _inspirationErrorMessage = null;
    _notifyIfActive();

    final dietOptionsResult = await _getInspirationOptionsUseCase.execute(
      'meal_preferences',
    );
    final allergyOptionsResult = await _getInspirationOptionsUseCase.execute(
      'allergies',
    );
    final dislikeOptionsResult = await _getInspirationOptionsUseCase.execute(
      'dislikes',
    );
    if (_isDisposed) return;

    dietOptionsResult.ifRight((items) {
      _dietOptions = _withRequiredOption(items, 'No specific diet');
    });
    allergyOptionsResult.ifRight((items) {
      _allergyOptions = _withRequiredOption(items, 'None');
    });
    dislikeOptionsResult.ifRight((items) {
      _dislikeOptions = _withRequiredOption(items, 'None');
    });

    _isInspirationOptionsLoading = false;
    _notifyIfActive();
  }

  Future<void> searchIngredients(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      _ingredientSearchResults = const [];
      _isIngredientSearching = false;
      _notifyIfActive();
      return;
    }

    _isIngredientSearching = true;
    _notifyIfActive();

    final result = await _searchIngredientsUseCase.execute(trimmed);
    if (_isDisposed) return;

    result.ifRight((items) => _ingredientSearchResults = items);
    result.ifLeft((failure) => _inspirationErrorMessage = failure.message);
    _isIngredientSearching = false;
    _notifyIfActive();
  }

  Future<void> searchPreferenceFoods(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      _preferenceSearchResults = const [];
      _isPreferenceSearching = false;
      _notifyIfActive();
      return;
    }

    _isPreferenceSearching = true;
    _notifyIfActive();

    final result = await _searchIngredientsUseCase.execute(trimmed);
    if (_isDisposed) return;

    result.ifRight((items) => _preferenceSearchResults = items);
    result.ifLeft((failure) => _inspirationErrorMessage = failure.message);
    _isPreferenceSearching = false;
    _notifyIfActive();
  }

  void selectWeatherCategory(String id) {
    _selectedWeatherCategoryId = id;
    _notifyIfActive();
  }

  void toggleIngredient(MealPlanInspirationIngredient ingredient) {
    final index = _selectedIngredients.indexWhere((item) {
      return item.name.toLowerCase() == ingredient.name.toLowerCase();
    });
    if (index >= 0) {
      _selectedIngredients.removeAt(index);
    } else {
      _selectedIngredients.add(ingredient);
    }
    _notifyIfActive();
  }

  void addCustomIngredient(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    toggleIngredient(
      MealPlanInspirationIngredient(
        id: trimmed.toLowerCase().replaceAll(RegExp(r'\s+'), '_'),
        name: trimmed,
        isCustom: true,
      ),
    );
  }

  bool isIngredientSelected(String name) {
    return _selectedIngredients.any(
      (item) => item.name.toLowerCase() == name.toLowerCase(),
    );
  }

  void selectOverrideDiet(String value) {
    _overrideDiet = value;
    _notifyIfActive();
  }

  void toggleOverrideAllergy(String value) {
    _toggleValue(_overrideAllergies, value);
    _notifyIfActive();
  }

  void toggleOverrideDislike(String value) {
    _toggleValue(_overrideDislikes, value);
    _notifyIfActive();
  }

  void addCustomOverrideAllergy(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    if (!_overrideAllergies.contains(trimmed)) {
      _overrideAllergies.remove('None');
      _overrideAllergies.add(trimmed);
    }
    _notifyIfActive();
  }

  void addCustomOverrideDislike(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    if (!_overrideDislikes.contains(trimmed)) {
      _overrideDislikes.remove('None');
      _overrideDislikes.add(trimmed);
    }
    _notifyIfActive();
  }

  void _replaceValues(List<String> target, List<String> source) {
    target
      ..clear()
      ..addAll(source);
  }

  void _toggleValue(List<String> values, String value) {
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

    values.remove('None');
    if (values.contains(value)) {
      values.remove(value);
    } else {
      values.add(value);
    }
  }

  List<MealPlanPreferenceOption> _withRequiredOption(
    List<MealPlanPreferenceOption> source,
    String name,
  ) {
    final hasOption = source.any(
      (item) => item.name.toLowerCase() == name.toLowerCase(),
    );
    if (hasOption) return source;
    return [
      MealPlanPreferenceOption(
        id: name.toLowerCase().replaceAll(' ', '_'),
        name: name,
      ),
      ...source,
    ];
  }

  String _filterIdForSection(MealPlanSection section) {
    final categoryId = section.mealCategoryId.trim();
    if (categoryId.isNotEmpty) return categoryId;
    return section.mealType.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      '_',
    );
  }

  void _normalizeSelectedFilter() {
    if (_selectedFilterId == allFilterId) return;
    final sections = _dashboard?.sections ?? const <MealPlanSection>[];
    final exists = sections.any(
      (section) => _filterIdForSection(section) == _selectedFilterId,
    );
    if (!exists) _selectedFilterId = allFilterId;
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
