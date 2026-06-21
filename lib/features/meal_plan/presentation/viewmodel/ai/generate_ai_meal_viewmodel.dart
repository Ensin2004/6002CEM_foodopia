import 'package:flutter/foundation.dart';

import '../../../../../core/extensions/either_extensions.dart';
import '../../../../../core/services/weather_category_service.dart';
import '../../../../recipe/domain/entities/add_recipe_basic_info.dart';
import '../../../../recipe/domain/entities/add_recipe_ingredient.dart';
import '../../../../recipe/domain/entities/add_recipe_instruction.dart';
import '../../../domain/entities/add_meal_ai_plan.dart';
import '../../../domain/entities/meal_calorie_guidance.dart';
import '../../../domain/services/meal_calorie_guidance_service.dart';
import '../../../domain/entities/meal_plan_inspiration_input.dart';
import '../../../domain/usecases/generate_ai_meal_ideas_usecase.dart';
import '../../../domain/usecases/get_add_meal_ai_plan_usecase.dart';
import '../../../domain/usecases/get_meal_plan_default_ingredients_usecase.dart';
import '../../../domain/usecases/get_meal_plan_inspiration_options_usecase.dart';
import '../../../domain/usecases/get_meal_categories_usecase.dart';
import '../../../domain/usecases/save_ai_meal_plan_usecase.dart';
import '../../../domain/usecases/search_meal_plan_ingredients_usecase.dart';

/// ViewModel for the Generate AI Meal feature.
/// Manages state for the multi-step AI meal generation wizard.
class GenerateAiMealViewModel extends ChangeNotifier {
  // =========================================================================
  // DEPENDENCIES
  // =========================================================================

  /// Use case for fetching the AI meal plan.
  final GetAddMealAiPlanUseCase _getPlanUseCase;

  /// Use case for generating AI meal ideas.
  final GenerateAiMealIdeasUseCase _generateIdeasUseCase;

  /// Use case for fetching meal categories.
  final GetMealCategoriesUseCase _getMealCategoriesUseCase;

  /// Use case for saving AI meal plans.
  final SaveAiMealPlanUseCase _saveAiMealPlanUseCase;

  /// Use case for fetching default ingredients.
  final GetMealPlanDefaultIngredientsUseCase _getDefaultIngredientsUseCase;

  /// Use case for fetching inspiration options.
  final GetMealPlanInspirationOptionsUseCase _getInspirationOptionsUseCase;

  /// Use case for searching ingredients.
  final SearchMealPlanIngredientsUseCase _searchIngredientsUseCase;

  /// User ID of the current user.
  final String userId;

  /// Type of meal to generate.
  final String mealType;

  /// Optional meal category ID.
  final String? mealCategoryId;

  /// Initial selected date.
  final DateTime? initialSelectedDate;

  /// Initial generation request.
  final AddMealAiGenerationRequest? initialRequest;

  /// Whether to auto-generate on load.
  final bool autoGenerate;

  /// Calorie budget for the selected day.
  final MealCalorieBudget calorieBudget;

  /// Existing planned meal names to avoid repeating.
  final List<String> existingMealNames;

  // =========================================================================
  // STATE
  // =========================================================================

  /// The AI meal plan data.
  AddMealAiPlan? _plan;

  /// Current step in the wizard (1-4).
  int _currentStep = 1;

  /// Whether data is loading.
  bool _isLoading = true;

  /// Whether generation is in progress.
  bool _isGenerating = false;

  /// Whether saving is in progress.
  bool _isSaving = false;

  /// Whether the ViewModel has been disposed.
  bool _isDisposed = false;

  /// Error message.
  String? _errorMessage;

  /// Selected weather category ID.
  String _selectedWeatherCategoryId = 'sunny';

  /// Dish include text input.
  String _dishIncludeText = '';

  /// Dish avoid text input.
  String _dishAvoidText = '';

  /// Selected cooking time in minutes.
  int _selectedCookingTime = 30;

  /// Selected difficulty level (1-5).
  int _selectedDifficultyLevel = 1;

  /// Selected serving size.
  int _selectedServingSize = 1;

  /// Selected date.
  DateTime? _selectedDate;

  /// Selected meal category.
  AddMealCategoryOption? _selectedMealCategory;

  /// List of meal categories.
  List<AddMealCategoryOption> _mealCategories = const [];

  /// List of meal preference options.
  List<MealPlanPreferenceOption> _mealPreferenceOptions = const [];

  /// List of allergy options.
  List<MealPlanPreferenceOption> _allergyOptions = const [];

  /// List of dislike options.
  List<MealPlanPreferenceOption> _dislikeOptions = const [];

  /// List of default ingredient options.
  List<MealPlanInspirationIngredient> _defaultIngredientOptions = const [];

  /// List of food search results.
  List<MealPlanInspirationIngredient> _foodSearchResults = const [];

  /// Selected meal preferences.
  final List<String> _selectedMealPreferences = [];

  /// Selected ingredients to include.
  final List<String> _selectedIngredientsToInclude = [];

  /// Selected ingredients to avoid.
  final List<String> _selectedIngredientsToAvoid = [];

  /// Selected recipe IDs.
  final Set<String> _selectedRecipeIds = {};

  /// Recipe draft basic info.
  AddRecipeBasicInfo? _recipeDraftBasicInfo;

  /// Recipe draft ingredients.
  List<AddRecipeIngredient> _recipeDraftIngredients = const [];

  /// Recipe draft instructions.
  List<AddRecipeInstruction> _recipeDraftInstructions = const [];

  /// Whether the recipe draft uses sections.
  bool _recipeDraftUseSections = false;

  /// Whether factor options are loading.
  bool _isFactorOptionsLoading = false;

  /// Whether food search is in progress.
  bool _isFoodSearching = false;

  // =========================================================================
  // CONSTRUCTOR
  // =========================================================================

  /// Creates a new GenerateAiMealViewModel.
  GenerateAiMealViewModel({
    required this.userId,
    required this.mealType,
    this.mealCategoryId,
    DateTime? selectedDate,
    this.initialRequest,
    this.autoGenerate = false,
    this.calorieBudget = const MealCalorieBudget.empty(),
    this.existingMealNames = const [],
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
    // Load the plan asynchronously after construction.
    Future.microtask(loadPlan);
  }

  // =========================================================================
  // GETTERS
  // =========================================================================

  /// The AI meal plan.
  AddMealAiPlan? get plan => _plan;

  /// Current step in the wizard.
  int get currentStep => _currentStep;

  /// Whether data is loading.
  bool get isLoading => _isLoading;

  /// Whether generation is in progress.
  bool get isGenerating => _isGenerating;

  /// Whether saving is in progress.
  bool get isSaving => _isSaving;

  /// Source request if available.
  AddMealAiGenerationRequest? get sourceRequest => initialRequest;

  /// Error message.
  String? get errorMessage => _errorMessage;

  /// List of weather categories.
  List<WeatherCategory> get weatherCategories =>
      WeatherCategoryService.categories;

  /// Selected weather category ID.
  String get selectedWeatherCategoryId => _selectedWeatherCategoryId;

  /// Selected weather category.
  WeatherCategory get selectedWeatherCategory =>
      WeatherCategoryService.byId(_selectedWeatherCategoryId);

  /// Selected meal preferences.
  List<String> get selectedMealPreferences =>
      List.unmodifiable(_selectedMealPreferences);

  /// Selected meal preference label.
  String get selectedMealPreferenceLabel => _selectedMealPreferences.isEmpty
      ? 'No Preference'
      : _selectedMealPreferences.join(', ');

  /// Dish include text.
  String get dishIncludeText => _dishIncludeText;

  /// Dish avoid text.
  String get dishAvoidText => _dishAvoidText;

  /// Selected cooking time.
  int get selectedCookingTime => _selectedCookingTime;

  /// Selected difficulty level.
  int get selectedDifficultyLevel => _selectedDifficultyLevel;

  /// Selected difficulty label.
  String get selectedDifficulty => _difficultyLabel(_selectedDifficultyLevel);

  /// Selected serving count.
  int get selectedServingCount => _selectedServingSize;

  /// Selected serving size label.
  String get selectedServingSize => _servingLabel(_selectedServingSize);

  /// Selected date.
  DateTime get selectedDate =>
      _selectedDate ?? _plan?.planningDate ?? DateTime.now();

  /// Selected meal category.
  AddMealCategoryOption? get selectedMealCategory => _selectedMealCategory;

  /// List of meal categories.
  List<AddMealCategoryOption> get mealCategories => _mealCategories;

  /// List of meal preference options.
  List<MealPlanPreferenceOption> get mealPreferenceOptions =>
      _mealPreferenceOptions;

  /// List of allergy options.
  List<MealPlanPreferenceOption> get allergyOptions => _allergyOptions;

  /// List of dislike options.
  List<MealPlanPreferenceOption> get dislikeOptions => _dislikeOptions;

  /// List of default ingredient options.
  List<MealPlanInspirationIngredient> get defaultIngredientOptions =>
      _defaultIngredientOptions;

  /// List of food search results.
  List<MealPlanInspirationIngredient> get foodSearchResults =>
      _foodSearchResults;

  /// Whether factor options are loading.
  bool get isFactorOptionsLoading => _isFactorOptionsLoading;

  /// Whether food search is in progress.
  bool get isFoodSearching => _isFoodSearching;

  /// Selected ingredients to avoid.
  List<String> get selectedIngredientsToAvoid =>
      List.unmodifiable(_selectedIngredientsToAvoid);

  /// Selected ingredients to include.
  List<String> get selectedIngredientsToInclude =>
      List.unmodifiable(_selectedIngredientsToInclude);

  /// Default ingredients to include.
  List<String> get defaultIngredientsToInclude =>
      List.unmodifiable(_defaultIngredientOptions.map((item) => item.name));

  /// Default allergies from preferences.
  List<String> get defaultAllergies =>
      List.unmodifiable(_plan?.preferences.allergies ?? const []);

  /// Default dislikes from preferences.
  List<String> get defaultDislikes =>
      List.unmodifiable(_plan?.preferences.dislikes ?? const []);

  /// Saved ingredients to avoid (allergies + dislikes).
  List<String> get savedIngredientsToAvoid {
    return [
      ...?_plan?.preferences.allergies,
      ...?_plan?.preferences.dislikes,
    ].where((item) => item.trim().isNotEmpty).toSet().toList();
  }

  /// Default ingredients to avoid (allergy options + dislike options).
  List<String> get defaultIngredientsToAvoid {
    return [
      ..._allergyOptions.map((item) => item.name),
      ..._dislikeOptions.map((item) => item.name),
    ].where((item) => item.trim().isNotEmpty).toSet().toList();
  }

  /// Selected dish includes.
  List<String> get selectedDishIncludes {
    if (_dishIncludeText.trim().isEmpty) return const [];
    return _splitInput(_dishIncludeText);
  }

  /// Selected dish avoids.
  List<String> get selectedDishAvoids {
    if (_dishAvoidText.trim().isEmpty) return const [];
    return _splitInput(_dishAvoidText);
  }

  /// Selected recipes.
  List<AddMealAiRecipe> get selectedRecipes {
    // Combine top matches and AI ideas.
    final recipes = [...?_plan?.topMatches, ...?_plan?.aiIdeas];

    // Deduplicate by ID.
    final unique = <String, AddMealAiRecipe>{};
    for (final recipe in recipes) {
      unique[recipe.id] = recipe;
    }

    // Filter by selected IDs.
    return unique.values
        .where((recipe) => _selectedRecipeIds.contains(recipe.id))
        .toList();
  }

  /// Calorie guidance for the first selected recipe.
  MealCalorieGuidance? get selectedRecipeCalorieGuidance {
    // Single-select recipe flow keeps the first selected recipe authoritative.
    final recipe = selectedRecipes.isEmpty ? null : selectedRecipes.first;
    if (recipe == null) return null;
    return calorieGuidanceFor(recipe);
  }

  /// Recipe draft basic info.
  AddRecipeBasicInfo? get recipeDraftBasicInfo => _recipeDraftBasicInfo;

  /// Recipe draft ingredients.
  List<AddRecipeIngredient> get recipeDraftIngredients =>
      _recipeDraftIngredients;

  /// Recipe draft instructions.
  List<AddRecipeInstruction> get recipeDraftInstructions =>
      _recipeDraftInstructions;

  /// Whether the recipe draft uses sections.
  bool get recipeDraftUseSections => _recipeDraftUseSections;

  /// Whether the recipe draft is complete.
  bool get hasRecipeDraft =>
      _recipeDraftBasicInfo != null &&
      _recipeDraftIngredients.isNotEmpty &&
      _recipeDraftInstructions.isNotEmpty;

  // =========================================================================
  // LOADING
  // =========================================================================

  /// Loads the AI meal plan from the repository.
  Future<void> loadPlan() async {
    // Set loading state.
    _isLoading = true;
    _errorMessage = null;
    _notifyIfActive();

    // Execute the use case.
    final result = await _getPlanUseCase.execute(
      userId: userId,
      mealType: mealType,
    );

    // Check if disposed.
    if (_isDisposed) return;

    // Handle success.
    result.ifRight((plan) {
      final request = initialRequest;

      // Use initial request if available.
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

      // Set selected date.
      _selectedDate =
          request?.planningDate ?? initialSelectedDate ?? plan.planningDate;

      // Match weather category.
      _selectedWeatherCategoryId = WeatherCategoryService.matchCondition(
        plan.weather.condition,
        plan.weather.temperature,
      ).id;

      // Set default ingredients.
      _replaceValues(_selectedIngredientsToInclude, plan.ingredientsToInclude);
      _replaceValues(_selectedIngredientsToAvoid, [
        ...plan.preferences.allergies,
        ...plan.preferences.dislikes,
      ]);

      // Set meal preferences.
      _selectedMealPreferences
        ..clear()
        ..addAll(
          plan.preferences.diet.trim().isEmpty
              ? const <String>[]
              : _splitInput(plan.preferences.diet),
        );

      // Override with initial request if available.
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

      // Clear selected recipes and draft.
      _selectedRecipeIds.clear();
      clearRecipeDraft(notify: false);
    });

    // Handle failure.
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    // Reset loading state.
    _isLoading = false;
    _notifyIfActive();

    // Load additional data.
    await loadMealCategories();
    await loadFactorOptions();

    // Auto-generate if enabled and no ideas exist.
    if (autoGenerate && _plan != null && _plan!.aiIdeas.isEmpty) {
      await generateIdeas();
    }
  }

  /// Loads meal categories.
  Future<void> loadMealCategories() async {
    // Execute the use case.
    final result = await _getMealCategoriesUseCase.execute();

    // Check if disposed.
    if (_isDisposed) return;

    // Handle success.
    result.ifRight((categories) {
      _mealCategories = categories;

      // Select the matching category.
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

  /// Loads factor options from the repository.
  Future<void> loadFactorOptions() async {
    // Set loading state.
    _isFactorOptionsLoading = true;
    _notifyIfActive();

    // Fetch all factor options in parallel.
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

    // Check if disposed.
    if (_isDisposed) return;

    // Handle results.
    mealPreferencesResult.ifRight((items) {
      _mealPreferenceOptions = items;
    });
    ingredientsResult.ifRight((items) {
      _defaultIngredientOptions = items;

      // Set default included ingredients if no initial request.
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

    // Reset loading state.
    _isFactorOptionsLoading = false;
    _notifyIfActive();
  }

  /// Searches for foods by query.
  Future<void> searchFoods(String query) async {
    // Trim the query.
    final trimmed = query.trim();

    // Clear results if query is too short.
    if (trimmed.length < 2) {
      _foodSearchResults = const [];
      _isFoodSearching = false;
      _notifyIfActive();
      return;
    }

    // Set searching state.
    _isFoodSearching = true;
    _notifyIfActive();

    // Execute the search.
    final result = await _searchIngredientsUseCase.execute(trimmed);

    // Check if disposed.
    if (_isDisposed) return;

    // Handle result.
    result.ifRight((items) => _foodSearchResults = items);
    result.ifLeft((failure) => _errorMessage = failure.message);

    // Reset searching state.
    _isFoodSearching = false;
    _notifyIfActive();
  }

  // =========================================================================
  // NAVIGATION
  // =========================================================================

  /// Navigates to the next step.
  void goToNextStep() {
    if (_currentStep >= 4) return;
    _currentStep += 1;
    _notifyIfActive();
  }

  /// Navigates to the previous step.
  void goToPreviousStep() {
    if (_currentStep <= 1) return;
    _currentStep -= 1;
    _notifyIfActive();
  }

  /// Navigates to the results step and generates ideas.
  void goToResults() {
    generateIdeas();
  }

  // =========================================================================
  // GENERATION
  // =========================================================================

  /// Generates AI meal ideas.
  Future<void> generateIdeas() async {
    // Get the current plan.
    final currentPlan = _plan;

    // Return if no plan or already generating.
    if (currentPlan == null || _isGenerating) return;

    // Set generating state.
    _isGenerating = true;
    _errorMessage = null;
    _currentStep = 2;
    _notifyIfActive();

    // Build the generation request.
    final request = generationRequest;

    // Execute the use case.
    final result = await _generateIdeasUseCase.execute(request);

    // Check if disposed.
    if (_isDisposed) return;

    // Handle success.
    result.ifRight((ideas) {
      _plan = AddMealAiPlan(
        planningDate: currentPlan.planningDate,
        mealType: currentPlan.mealType,
        weather: request.weather,
        preferences: currentPlan.preferences,
        ingredientsToInclude: request.ingredientsToInclude,
        ingredientsToAvoid: request.ingredientsToAvoid,
        dishPreferences: currentPlan.dishPreferences,
        topMatches: const [],
        aiIdeas: ideas,
      );
      _selectedRecipeIds.clear();
    });

    // Handle failure.
    result.ifLeft((failure) => _errorMessage = failure.message);

    // Reset generating state.
    _isGenerating = false;
    _notifyIfActive();
  }

  /// Builds the generation request from current state.
  AddMealAiGenerationRequest get generationRequest {
    // Get preferences from plan or use defaults.
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
      calorieBudget: calorieBudget,
      existingMealNames: _mergedExistingMealNames,
    );
  }

  List<String> get _mergedExistingMealNames {
    return [...existingMealNames, ...?initialRequest?.existingMealNames]
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }

  /// Builds calorie guidance for a candidate AI recipe.
  MealCalorieGuidance calorieGuidanceFor(AddMealAiRecipe recipe) {
    /*
     * AI recipe cards and review cards share one target calculation.
     * Recipe calories are stored in kcal before display-unit conversion.
     */
    return MealCalorieGuidanceService().evaluate(
      budget: calorieBudget,
      mealCalories: recipe.calories,
    );
  }

  // =========================================================================
  // RECIPE SELECTION
  // =========================================================================

  /// Toggles a recipe selection.
  void toggleRecipe(String recipeId) {
    // Toggle the selection.
    if (_selectedRecipeIds.contains(recipeId)) {
      _selectedRecipeIds.remove(recipeId);
    } else {
      _selectedRecipeIds.clear();
      _selectedRecipeIds.add(recipeId);
    }

    // Clear the recipe draft.
    clearRecipeDraft(notify: false);
    _notifyIfActive();
  }

  /// Checks if a recipe is selected.
  bool isRecipeSelected(String recipeId) {
    return _selectedRecipeIds.contains(recipeId);
  }

  /// Replaces the selected AI recipe id with the saved library recipe id.
  void linkSelectedRecipeToSavedRecipe(String savedRecipeId) {
    final currentPlan = _plan;
    final selectedId = _selectedRecipeIds.isEmpty
        ? ''
        : _selectedRecipeIds.first;
    final trimmedSavedId = savedRecipeId.trim();
    if (currentPlan == null || selectedId.isEmpty || trimmedSavedId.isEmpty) {
      return;
    }

    AddMealAiRecipe replaceIfSelected(AddMealAiRecipe recipe) {
      if (recipe.id != selectedId) return recipe;
      return AddMealAiRecipe(
        id: trimmedSavedId,
        title: recipe.title,
        durationLabel: recipe.durationLabel,
        difficultyLabel: recipe.difficultyLabel,
        servingLabel: recipe.servingLabel,
        imagePath: recipe.imagePath,
        imageBase64: recipe.imageBase64,
        description: recipe.description,
        reasons: recipe.reasons,
        ingredients: recipe.ingredients,
        instructions: recipe.instructions,
        calories: recipe.calories,
        carbohydrates: recipe.carbohydrates,
        fat: recipe.fat,
        protein: recipe.protein,
        imagePrompt: recipe.imagePrompt,
        categoryName: recipe.categoryName,
      );
    }

    _plan = AddMealAiPlan(
      planningDate: currentPlan.planningDate,
      mealType: currentPlan.mealType,
      weather: currentPlan.weather,
      preferences: currentPlan.preferences,
      ingredientsToInclude: currentPlan.ingredientsToInclude,
      ingredientsToAvoid: currentPlan.ingredientsToAvoid,
      dishPreferences: currentPlan.dishPreferences,
      topMatches: currentPlan.topMatches.map(replaceIfSelected).toList(),
      aiIdeas: currentPlan.aiIdeas.map(replaceIfSelected).toList(),
    );
    _selectedRecipeIds
      ..clear()
      ..add(trimmedSavedId);
    _notifyIfActive();
  }

  // =========================================================================
  // RECIPE DRAFT
  // =========================================================================

  /// Saves the recipe draft basic info.
  void saveRecipeDraftBasicInfo(AddRecipeBasicInfo value) {
    _recipeDraftBasicInfo = value;
    _recipeDraftIngredients = const [];
    _recipeDraftInstructions = const [];
    _recipeDraftUseSections = false;
    _notifyIfActive();
  }

  /// Saves the recipe draft ingredients.
  void saveRecipeDraftIngredients(List<AddRecipeIngredient> value) {
    _recipeDraftIngredients = List.unmodifiable(value);
    _recipeDraftInstructions = const [];
    _recipeDraftUseSections = false;
    _notifyIfActive();
  }

  /// Saves the recipe draft instructions.
  void saveRecipeDraftInstructions({
    required List<AddRecipeInstruction> instructions,
    required bool useSections,
  }) {
    _recipeDraftInstructions = List.unmodifiable(instructions);
    _recipeDraftUseSections = useSections;
    _notifyIfActive();
  }

  /// Clears the recipe draft.
  void clearRecipeDraft({bool notify = true}) {
    _recipeDraftBasicInfo = null;
    _recipeDraftIngredients = const [];
    _recipeDraftInstructions = const [];
    _recipeDraftUseSections = false;
    if (notify) _notifyIfActive();
  }

  // =========================================================================
  // FACTOR CONTROLS
  // =========================================================================

  /// Selects a weather category.
  void selectWeatherCategory(String id) {
    _selectedWeatherCategoryId = id;
    _notifyIfActive();
  }

  /// Toggles a meal preference.
  void toggleMealPreference(String value) {
    _toggleValue(_selectedMealPreferences, value);
    _notifyIfActive();
  }

  /// Toggles an ingredient to include.
  void toggleIngredientToInclude(String value) {
    _toggleValue(_selectedIngredientsToInclude, value);
    _notifyIfActive();
  }

  /// Toggles an ingredient to avoid.
  void toggleIngredientToAvoid(String value) {
    _toggleValue(_selectedIngredientsToAvoid, value);
    _notifyIfActive();
  }

  /// Adds an ingredient to include.
  void addIngredientToInclude(String value) {
    _addValue(_selectedIngredientsToInclude, value);
    _notifyIfActive();
  }

  /// Adds an ingredient to avoid.
  void addIngredientToAvoid(String value) {
    _addValue(_selectedIngredientsToAvoid, value);
    _notifyIfActive();
  }

  /// Updates the dish include text.
  void updateDishIncludeText(String value) {
    _dishIncludeText = value;
    _notifyIfActive();
  }

  /// Updates the dish avoid text.
  void updateDishAvoidText(String value) {
    _dishAvoidText = value;
    _notifyIfActive();
  }

  /// Updates the cooking time.
  void updateCookingTime(String value) {
    final minutes = int.tryParse(value.trim());
    if (minutes == null || minutes <= 0) return;
    _selectedCookingTime = minutes;
    _notifyIfActive();
  }

  /// Selects a difficulty level.
  void selectDifficulty(int value) {
    _selectedDifficultyLevel = value;
    _notifyIfActive();
  }

  /// Selects a serving size.
  void selectServingSize(String value) {
    final servings = int.tryParse(value.trim());
    if (servings == null || servings <= 0) return;
    _selectedServingSize = servings;
    _notifyIfActive();
  }

  /// Selects a date.
  void selectDate(DateTime value) {
    _selectedDate = DateTime(value.year, value.month, value.day);
    _notifyIfActive();
  }

  /// Selects a meal category.
  void selectMealCategory(AddMealCategoryOption value) {
    _selectedMealCategory = value;
    _notifyIfActive();
  }

  // =========================================================================
  // SAVE
  // =========================================================================

  /// Saves selected recipes to the meal plan.
  Future<bool> saveSelectedRecipesToPlan() async {
    // Get the selected category and recipes.
    final category = _selectedMealCategory;
    if (category == null || selectedRecipes.isEmpty) return false;

    // Set saving state.
    _isSaving = true;
    _errorMessage = null;
    _notifyIfActive();

    // Execute the use case.
    final result = await _saveAiMealPlanUseCase.execute(
      userId: userId,
      date: selectedDate,
      mealCategory: category,
      recipes: selectedRecipes,
      request: generationRequest,
    );

    // Check if disposed.
    if (_isDisposed) return false;

    // Handle result.
    final success = result.isRight();
    result.ifLeft((failure) => _errorMessage = failure.message);

    // Reset saving state.
    _isSaving = false;
    _notifyIfActive();

    return success;
  }

  // =========================================================================
  // PRIVATE HELPERS
  // =========================================================================

  /// Splits a comma-separated string into a list.
  List<String> _splitInput(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  /// Returns the selected weather snapshot.
  AddMealWeather get selectedWeatherSnapshot {
    // Get base weather from plan.
    final base = _plan?.weather;

    // Get the selected category.
    final category = selectedWeatherCategory;

    return AddMealWeather(
      temperature: base?.temperature ?? 28,
      condition: category.label,
      summary: category.description,
    );
  }

  /// Replaces values in a list with a source list.
  void _replaceValues(List<String> target, List<String> source) {
    target
      ..clear()
      ..addAll(source.where((item) => item.trim().isNotEmpty));
  }

  /// Toggles a value in a list.
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

  /// Adds a value to a list if not already present.
  void _addValue(List<String> values, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    final exists = values.any(
      (item) => item.toLowerCase() == trimmed.toLowerCase(),
    );

    if (!exists) values.add(trimmed);
  }

  /// Returns a difficulty label for a level.
  String _difficultyLabel(int level) {
    const labels = ['Novice', 'Beginner', 'Intermediate', 'Advanced', 'Master'];
    return labels[(level - 1).clamp(0, labels.length - 1)];
  }

  /// Returns a difficulty level for a label.
  int _difficultyLevelFor(String label) {
    const labels = ['novice', 'beginner', 'intermediate', 'advanced', 'master'];
    final normalized = label.toLowerCase();

    // Check for exact matches.
    final index = labels.indexWhere((item) => normalized.contains(item));
    if (index >= 0) return index + 1;

    // Check for common aliases.
    if (normalized.contains('easy')) return 1;
    if (normalized.contains('medium')) return 3;
    if (normalized.contains('hard')) return 4;

    // Return default.
    return 1;
  }

  /// Returns a serving label for a count.
  String _servingLabel(int count) {
    return count == 1 ? '1 serving' : '$count servings';
  }

  /// Returns a serving count for a label.
  int _servingCountFor(String label) {
    final match = RegExp(r'\d+').firstMatch(label);
    return int.tryParse(match?.group(0) ?? '') ?? 1;
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
