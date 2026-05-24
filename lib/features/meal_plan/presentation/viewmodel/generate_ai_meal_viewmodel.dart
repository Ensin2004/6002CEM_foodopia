import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../../../core/services/weather_category_service.dart';
import '../../domain/entities/add_meal_ai_plan.dart';
import '../../domain/entities/meal_plan_inspiration_input.dart';
import '../../domain/usecases/generate_ai_meal_ideas_usecase.dart';
import '../../domain/usecases/get_add_meal_ai_plan_usecase.dart';
import '../../domain/usecases/get_meal_plan_default_ingredients_usecase.dart';
import '../../domain/usecases/get_meal_plan_inspiration_options_usecase.dart';
import '../../domain/usecases/get_meal_categories_usecase.dart';
import '../../domain/usecases/save_ai_meal_plan_usecase.dart';
import '../../domain/usecases/search_meal_plan_ingredients_usecase.dart';

class GenerateAiMealViewModel extends ChangeNotifier {
  final GetAddMealAiPlanUseCase _getPlanUseCase;
  final GenerateAiMealIdeasUseCase _generateIdeasUseCase;
  final GetMealCategoriesUseCase _getMealCategoriesUseCase;
  final SaveAiMealPlanUseCase _saveAiMealPlanUseCase;
  final GetMealPlanDefaultIngredientsUseCase _getDefaultIngredientsUseCase;
  final GetMealPlanInspirationOptionsUseCase _getInspirationOptionsUseCase;
  final SearchMealPlanIngredientsUseCase _searchIngredientsUseCase;
  final String userId;
  final String mealType;
  final String? mealCategoryId;
  final DateTime? initialSelectedDate;
  final AddMealAiGenerationRequest? initialRequest;
  final bool autoGenerate;

  AddMealAiPlan? _plan;
  int _currentStep = 1;
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isSaving = false;
  bool _isDisposed = false;
  String? _errorMessage;
  String _selectedWeatherCategoryId = 'sunny';
  String _dishIncludeText = '';
  String _dishAvoidText = '';
  int _selectedCookingTime = 30;
  int _selectedDifficultyLevel = 1;
  int _selectedServingSize = 1;
  DateTime? _selectedDate;
  AddMealCategoryOption? _selectedMealCategory;
  List<AddMealCategoryOption> _mealCategories = const [];
  List<MealPlanPreferenceOption> _mealPreferenceOptions = const [];
  List<MealPlanPreferenceOption> _allergyOptions = const [];
  List<MealPlanPreferenceOption> _dislikeOptions = const [];
  List<MealPlanInspirationIngredient> _defaultIngredientOptions = const [];
  List<MealPlanInspirationIngredient> _foodSearchResults = const [];
  final List<String> _selectedMealPreferences = [];
  final List<String> _selectedIngredientsToInclude = [];
  final List<String> _selectedIngredientsToAvoid = [];
  final Set<String> _selectedRecipeIds = {};
  bool _isFactorOptionsLoading = false;
  bool _isFoodSearching = false;

  GenerateAiMealViewModel({
    required this.userId,
    required this.mealType,
    this.mealCategoryId,
    DateTime? selectedDate,
    this.initialRequest,
    this.autoGenerate = false,
    required GetAddMealAiPlanUseCase getPlanUseCase,
    required GenerateAiMealIdeasUseCase generateIdeasUseCase,
    required GetMealCategoriesUseCase getMealCategoriesUseCase,
    required SaveAiMealPlanUseCase saveAiMealPlanUseCase,
    required GetMealPlanDefaultIngredientsUseCase getDefaultIngredientsUseCase,
    required GetMealPlanInspirationOptionsUseCase getInspirationOptionsUseCase,
    required SearchMealPlanIngredientsUseCase searchIngredientsUseCase,
  }) : initialSelectedDate = selectedDate,
       _getPlanUseCase = getPlanUseCase,
       _generateIdeasUseCase = generateIdeasUseCase,
       _getMealCategoriesUseCase = getMealCategoriesUseCase,
       _saveAiMealPlanUseCase = saveAiMealPlanUseCase,
       _getDefaultIngredientsUseCase = getDefaultIngredientsUseCase,
       _getInspirationOptionsUseCase = getInspirationOptionsUseCase,
       _searchIngredientsUseCase = searchIngredientsUseCase {
    Future.microtask(loadPlan);
  }

  AddMealAiPlan? get plan => _plan;
  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  bool get isGenerating => _isGenerating;
  bool get isSaving => _isSaving;
  bool get showDatabaseResults => initialRequest == null;
  AddMealAiGenerationRequest? get sourceRequest => initialRequest;
  String? get errorMessage => _errorMessage;
  List<WeatherCategory> get weatherCategories =>
      WeatherCategoryService.categories;
  String get selectedWeatherCategoryId => _selectedWeatherCategoryId;
  WeatherCategory get selectedWeatherCategory =>
      WeatherCategoryService.byId(_selectedWeatherCategoryId);
  List<String> get selectedMealPreferences =>
      List.unmodifiable(_selectedMealPreferences);
  String get selectedMealPreferenceLabel => _selectedMealPreferences.isEmpty
      ? 'No Preference'
      : _selectedMealPreferences.join(', ');
  String get dishIncludeText => _dishIncludeText;
  String get dishAvoidText => _dishAvoidText;
  int get selectedCookingTime => _selectedCookingTime;
  int get selectedDifficultyLevel => _selectedDifficultyLevel;
  String get selectedDifficulty => _difficultyLabel(_selectedDifficultyLevel);
  int get selectedServingCount => _selectedServingSize;
  String get selectedServingSize => _servingLabel(_selectedServingSize);
  DateTime get selectedDate =>
      _selectedDate ?? _plan?.planningDate ?? DateTime.now();
  AddMealCategoryOption? get selectedMealCategory => _selectedMealCategory;
  List<AddMealCategoryOption> get mealCategories => _mealCategories;
  List<MealPlanPreferenceOption> get mealPreferenceOptions =>
      _mealPreferenceOptions;
  List<MealPlanPreferenceOption> get allergyOptions => _allergyOptions;
  List<MealPlanPreferenceOption> get dislikeOptions => _dislikeOptions;
  List<MealPlanInspirationIngredient> get defaultIngredientOptions =>
      _defaultIngredientOptions;
  List<MealPlanInspirationIngredient> get foodSearchResults =>
      _foodSearchResults;
  bool get isFactorOptionsLoading => _isFactorOptionsLoading;
  bool get isFoodSearching => _isFoodSearching;
  List<String> get selectedIngredientsToAvoid =>
      List.unmodifiable(_selectedIngredientsToAvoid);

  List<String> get selectedIngredientsToInclude =>
      List.unmodifiable(_selectedIngredientsToInclude);

  List<String> get defaultIngredientsToInclude =>
      List.unmodifiable(_defaultIngredientOptions.map((item) => item.name));

  List<String> get defaultAllergies =>
      List.unmodifiable(_plan?.preferences.allergies ?? const []);

  List<String> get defaultDislikes =>
      List.unmodifiable(_plan?.preferences.dislikes ?? const []);

  List<String> get savedIngredientsToAvoid {
    return [
      ...?_plan?.preferences.allergies,
      ...?_plan?.preferences.dislikes,
    ].where((item) => item.trim().isNotEmpty).toSet().toList();
  }

  List<String> get defaultIngredientsToAvoid {
    return [
      ..._allergyOptions.map((item) => item.name),
      ..._dislikeOptions.map((item) => item.name),
    ].where((item) => item.trim().isNotEmpty).toSet().toList();
  }

  List<String> get selectedDishIncludes {
    if (_dishIncludeText.trim().isEmpty) return const [];
    return _splitInput(_dishIncludeText);
  }

  List<String> get selectedDishAvoids {
    if (_dishAvoidText.trim().isEmpty) return const [];
    return _splitInput(_dishAvoidText);
  }

  List<AddMealAiRecipe> get selectedRecipes {
    final recipes = [...?_plan?.topMatches, ...?_plan?.aiIdeas];
    final unique = <String, AddMealAiRecipe>{};
    for (final recipe in recipes) {
      unique[recipe.id] = recipe;
    }
    return unique.values
        .where((recipe) => _selectedRecipeIds.contains(recipe.id))
        .toList();
  }

  Future<void> loadPlan() async {
    _isLoading = true;
    _errorMessage = null;
    _notifyIfActive();

    final result = await _getPlanUseCase.execute(
      userId: userId,
      mealType: mealType,
    );
    if (_isDisposed) return;

    result.ifRight((plan) {
      final request = initialRequest;
      _plan = request == null
          ? plan
          : AddMealAiPlan(
              planningDate: request.planningDate,
              mealType: request.mealType,
              weather: request.weather,
              preferences: request.preferences,
              ingredientsToInclude: request.ingredientsToInclude,
              ingredientsToAvoid: request.ingredientsToAvoid,
              dishPreferences: plan.dishPreferences,
              topMatches: const [],
              aiIdeas: const [],
            );
      _selectedDate =
          request?.planningDate ?? initialSelectedDate ?? plan.planningDate;
      _selectedWeatherCategoryId = WeatherCategoryService.matchCondition(
        plan.weather.condition,
        plan.weather.temperature,
      ).id;
      _replaceValues(_selectedIngredientsToInclude, plan.ingredientsToInclude);
      _replaceValues(_selectedIngredientsToAvoid, [
        ...plan.preferences.allergies,
        ...plan.preferences.dislikes,
      ]);
      _selectedMealPreferences
        ..clear()
        ..addAll(
          plan.preferences.diet.trim().isEmpty
              ? const <String>[]
              : _splitInput(plan.preferences.diet),
        );
      if (request != null) {
        _selectedWeatherCategoryId = WeatherCategoryService.matchCondition(
          request.weather.condition,
          request.weather.temperature,
        ).id;
        _replaceValues(
          _selectedMealPreferences,
          _splitInput(request.preferences.diet),
        );
        _replaceValues(
          _selectedIngredientsToInclude,
          request.ingredientsToInclude,
        );
        _replaceValues(_selectedIngredientsToAvoid, request.ingredientsToAvoid);
        _dishIncludeText = request.dishIncludes.join(', ');
        _dishAvoidText = request.dishAvoids.join(', ');
        _selectedCookingTime = request.cookingTime;
        _selectedDifficultyLevel = _difficultyLevelFor(request.difficulty);
        _selectedServingSize = _servingCountFor(request.servingSize);
      }
      _selectedRecipeIds.clear();
    });
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    _isLoading = false;
    _notifyIfActive();
    await loadMealCategories();
    await loadFactorOptions();
    if (autoGenerate && _plan != null && _plan!.aiIdeas.isEmpty) {
      await generateIdeas();
    }
  }

  Future<void> loadMealCategories() async {
    final result = await _getMealCategoriesUseCase.execute();
    if (_isDisposed) return;
    result.ifRight((categories) {
      _mealCategories = categories;
      _selectedMealCategory = categories.firstWhere(
        (item) =>
            item.id == mealCategoryId ||
            item.name.toLowerCase() == mealType.toLowerCase(),
        orElse: () => categories.isEmpty
            ? const AddMealCategoryOption(id: 'breakfast', name: 'Breakfast')
            : categories.first,
      );
    });
    _notifyIfActive();
  }

  Future<void> loadFactorOptions() async {
    _isFactorOptionsLoading = true;
    _notifyIfActive();

    final mealPreferencesResult = await _getInspirationOptionsUseCase.execute(
      'meal_preferences',
    );
    final ingredientsResult = await _getDefaultIngredientsUseCase.execute();
    final allergiesResult = await _getInspirationOptionsUseCase.execute(
      'allergies',
    );
    final dislikesResult = await _getInspirationOptionsUseCase.execute(
      'dislikes',
    );
    if (_isDisposed) return;

    mealPreferencesResult.ifRight((items) {
      _mealPreferenceOptions = items;
    });
    ingredientsResult.ifRight((items) {
      _defaultIngredientOptions = items;
      if (initialRequest == null) {
        _replaceValues(
          _selectedIngredientsToInclude,
          items.map((item) => item.name).toList(),
        );
      }
    });
    allergiesResult.ifRight((items) {
      _allergyOptions = items;
    });
    dislikesResult.ifRight((items) {
      _dislikeOptions = items;
    });

    _isFactorOptionsLoading = false;
    _notifyIfActive();
  }

  Future<void> searchFoods(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) {
      _foodSearchResults = const [];
      _isFoodSearching = false;
      _notifyIfActive();
      return;
    }

    _isFoodSearching = true;
    _notifyIfActive();

    final result = await _searchIngredientsUseCase.execute(trimmed);
    if (_isDisposed) return;

    result.ifRight((items) => _foodSearchResults = items);
    result.ifLeft((failure) => _errorMessage = failure.message);
    _isFoodSearching = false;
    _notifyIfActive();
  }

  void goToNextStep() {
    if (_currentStep >= 4) return;
    _currentStep += 1;
    _notifyIfActive();
  }

  void goToPreviousStep() {
    if (_currentStep <= 1) return;
    _currentStep -= 1;
    _notifyIfActive();
  }

  void goToResults() {
    generateIdeas();
  }

  Future<void> generateIdeas() async {
    final currentPlan = _plan;
    if (currentPlan == null || _isGenerating) return;

    _isGenerating = true;
    _errorMessage = null;
    _currentStep = 2;
    _notifyIfActive();

    final request = generationRequest;
    final result = await _generateIdeasUseCase.execute(request);
    if (_isDisposed) return;

    result.ifRight((ideas) {
      _plan = AddMealAiPlan(
        planningDate: currentPlan.planningDate,
        mealType: currentPlan.mealType,
        weather: request.weather,
        preferences: currentPlan.preferences,
        ingredientsToInclude: request.ingredientsToInclude,
        ingredientsToAvoid: request.ingredientsToAvoid,
        dishPreferences: currentPlan.dishPreferences,
        topMatches: showDatabaseResults ? currentPlan.topMatches : const [],
        aiIdeas: ideas,
      );
      _selectedRecipeIds.clear();
    });
    result.ifLeft((failure) => _errorMessage = failure.message);

    _isGenerating = false;
    _notifyIfActive();
  }

  AddMealAiGenerationRequest get generationRequest {
    final preferences =
        _plan?.preferences ??
        const AddMealPreferenceSnapshot(
          diet: 'No Preference',
          allergies: [],
          dislikes: [],
        );
    return AddMealAiGenerationRequest(
      planningDate: selectedDate,
      mealType: _selectedMealCategory?.name ?? mealType,
      weather: selectedWeatherSnapshot,
      preferences: AddMealPreferenceSnapshot(
        diet: selectedMealPreferenceLabel,
        allergies: preferences.allergies
            .where(
              (item) => selectedIngredientsToAvoid.any(
                (selected) => selected.toLowerCase() == item.toLowerCase(),
              ),
            )
            .toList(),
        dislikes: selectedIngredientsToAvoid,
      ),
      ingredientsToInclude: selectedIngredientsToInclude,
      ingredientsToAvoid: selectedIngredientsToAvoid,
      dishIncludes: selectedDishIncludes,
      dishAvoids: selectedDishAvoids,
      cookingTime: _selectedCookingTime,
      difficultyLevel: _selectedDifficultyLevel,
      difficulty: selectedDifficulty,
      servingCount: _selectedServingSize,
      servingSize: selectedServingSize,
    );
  }

  void toggleRecipe(String recipeId) {
    if (_selectedRecipeIds.contains(recipeId)) {
      _selectedRecipeIds.remove(recipeId);
    } else {
      _selectedRecipeIds.clear();
      _selectedRecipeIds.add(recipeId);
    }
    _notifyIfActive();
  }

  bool isRecipeSelected(String recipeId) {
    return _selectedRecipeIds.contains(recipeId);
  }

  void selectWeatherCategory(String id) {
    _selectedWeatherCategoryId = id;
    _notifyIfActive();
  }

  void toggleMealPreference(String value) {
    _toggleValue(_selectedMealPreferences, value);
    _notifyIfActive();
  }

  void toggleIngredientToInclude(String value) {
    _toggleValue(_selectedIngredientsToInclude, value);
    _notifyIfActive();
  }

  void toggleIngredientToAvoid(String value) {
    _toggleValue(_selectedIngredientsToAvoid, value);
    _notifyIfActive();
  }

  void addIngredientToInclude(String value) {
    _addValue(_selectedIngredientsToInclude, value);
    _notifyIfActive();
  }

  void addIngredientToAvoid(String value) {
    _addValue(_selectedIngredientsToAvoid, value);
    _notifyIfActive();
  }

  void updateDishIncludeText(String value) {
    _dishIncludeText = value;
    _notifyIfActive();
  }

  void updateDishAvoidText(String value) {
    _dishAvoidText = value;
    _notifyIfActive();
  }

  void updateCookingTime(String value) {
    final minutes = int.tryParse(value.trim());
    if (minutes == null || minutes <= 0) return;
    _selectedCookingTime = minutes;
    _notifyIfActive();
  }

  void selectDifficulty(int value) {
    _selectedDifficultyLevel = value;
    _notifyIfActive();
  }

  void selectServingSize(String value) {
    final servings = int.tryParse(value.trim());
    if (servings == null || servings <= 0) return;
    _selectedServingSize = servings;
    _notifyIfActive();
  }

  void selectDate(DateTime value) {
    _selectedDate = DateTime(value.year, value.month, value.day);
    _notifyIfActive();
  }

  void selectMealCategory(AddMealCategoryOption value) {
    _selectedMealCategory = value;
    _notifyIfActive();
  }

  Future<bool> saveSelectedRecipesToPlan() async {
    final category = _selectedMealCategory;
    if (category == null || selectedRecipes.isEmpty) return false;

    _isSaving = true;
    _errorMessage = null;
    _notifyIfActive();

    final result = await _saveAiMealPlanUseCase.execute(
      userId: userId,
      date: selectedDate,
      mealCategory: category,
      recipes: selectedRecipes,
      request: generationRequest,
    );
    if (_isDisposed) return false;

    final success = result.isRight();
    result.ifLeft((failure) => _errorMessage = failure.message);
    _isSaving = false;
    _notifyIfActive();
    return success;
  }

  List<String> _splitInput(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  AddMealWeather get selectedWeatherSnapshot {
    final base = _plan?.weather;
    final category = selectedWeatherCategory;
    return AddMealWeather(
      temperature: base?.temperature ?? 28,
      condition: category.label,
      summary: category.description,
    );
  }

  void _replaceValues(List<String> target, List<String> source) {
    target
      ..clear()
      ..addAll(source.where((item) => item.trim().isNotEmpty));
  }

  void _toggleValue(List<String> values, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed == 'No Preference') return;
    final index = values.indexWhere(
      (item) => item.toLowerCase() == trimmed.toLowerCase(),
    );
    if (index >= 0) {
      values.removeAt(index);
    } else {
      values.add(trimmed);
    }
  }

  void _addValue(List<String> values, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    final exists = values.any(
      (item) => item.toLowerCase() == trimmed.toLowerCase(),
    );
    if (!exists) values.add(trimmed);
  }

  String _difficultyLabel(int level) {
    const labels = ['Novice', 'Beginner', 'Intermediate', 'Advanced', 'Master'];
    return labels[(level - 1).clamp(0, labels.length - 1)];
  }

  int _difficultyLevelFor(String label) {
    const labels = ['novice', 'beginner', 'intermediate', 'advanced', 'master'];
    final normalized = label.toLowerCase();
    final index = labels.indexWhere((item) => normalized.contains(item));
    if (index >= 0) return index + 1;
    if (normalized.contains('easy')) return 1;
    if (normalized.contains('medium')) return 3;
    if (normalized.contains('hard')) return 4;
    return 1;
  }

  String _servingLabel(int count) {
    return count == 1 ? '1 serving' : '$count servings';
  }

  int _servingCountFor(String label) {
    final match = RegExp(r'\d+').firstMatch(label);
    return int.tryParse(match?.group(0) ?? '') ?? 1;
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
