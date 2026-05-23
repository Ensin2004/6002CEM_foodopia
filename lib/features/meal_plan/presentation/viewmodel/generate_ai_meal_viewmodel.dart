import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/add_meal_ai_plan.dart';
import '../../domain/usecases/generate_ai_meal_ideas_usecase.dart';
import '../../domain/usecases/get_add_meal_ai_plan_usecase.dart';
import '../../domain/usecases/get_meal_categories_usecase.dart';
import '../../domain/usecases/save_ai_meal_plan_usecase.dart';

class GenerateAiMealViewModel extends ChangeNotifier {
  final GetAddMealAiPlanUseCase _getPlanUseCase;
  final GenerateAiMealIdeasUseCase _generateIdeasUseCase;
  final GetMealCategoriesUseCase _getMealCategoriesUseCase;
  final SaveAiMealPlanUseCase _saveAiMealPlanUseCase;
  final String userId;
  final String mealType;
  final AddMealAiGenerationRequest? initialRequest;
  final bool autoGenerate;

  AddMealAiPlan? _plan;
  int _currentStep = 1;
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isSaving = false;
  bool _isDisposed = false;
  String? _errorMessage;
  String _selectedMealPreference = 'No Preference';
  String _ingredientIncludeText = '';
  String _ingredientAvoidText = '';
  String _dishIncludeText = '';
  String _dishAvoidText = '';
  int _selectedCookingTime = 30;
  String _selectedDifficulty = 'Any';
  String _selectedServingSize = 'Any';
  DateTime? _selectedDate;
  AddMealCategoryOption? _selectedMealCategory;
  List<AddMealCategoryOption> _mealCategories = const [];
  final Set<String> _selectedRecipeIds = {};

  GenerateAiMealViewModel({
    required this.userId,
    required this.mealType,
    this.initialRequest,
    this.autoGenerate = false,
    required GetAddMealAiPlanUseCase getPlanUseCase,
    required GenerateAiMealIdeasUseCase generateIdeasUseCase,
    required GetMealCategoriesUseCase getMealCategoriesUseCase,
    required SaveAiMealPlanUseCase saveAiMealPlanUseCase,
  }) : _getPlanUseCase = getPlanUseCase,
       _generateIdeasUseCase = generateIdeasUseCase,
       _getMealCategoriesUseCase = getMealCategoriesUseCase,
       _saveAiMealPlanUseCase = saveAiMealPlanUseCase {
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
  String get selectedMealPreference => _selectedMealPreference;
  String get ingredientIncludeText => _ingredientIncludeText;
  String get ingredientAvoidText => _ingredientAvoidText;
  String get dishIncludeText => _dishIncludeText;
  String get dishAvoidText => _dishAvoidText;
  int get selectedCookingTime => _selectedCookingTime;
  String get selectedDifficulty => _selectedDifficulty;
  String get selectedServingSize => _selectedServingSize;
  DateTime get selectedDate =>
      _selectedDate ?? _plan?.planningDate ?? DateTime.now();
  AddMealCategoryOption? get selectedMealCategory => _selectedMealCategory;
  List<AddMealCategoryOption> get mealCategories => _mealCategories;
  List<String> get selectedIngredientsToAvoid {
    final values = <String>[
      ...?_plan?.preferences.dislikes,
      if (_ingredientAvoidText.trim().isNotEmpty)
        ..._splitInput(_ingredientAvoidText),
    ];
    return values.toSet().toList();
  }

  List<String> get selectedIngredientsToInclude {
    if (_ingredientIncludeText.trim().isEmpty) return const [];
    return _splitInput(_ingredientIncludeText);
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
      _selectedDate = request?.planningDate ?? plan.planningDate;
      _selectedMealPreference = plan.preferences.diet.trim().isEmpty
          ? 'No Preference'
          : plan.preferences.diet;
      if (request != null) {
        _selectedMealPreference = request.preferences.diet;
        _ingredientIncludeText = request.ingredientsToInclude.join(', ');
        _ingredientAvoidText = request.ingredientsToAvoid.join(', ');
        _dishIncludeText = request.dishIncludes.join(', ');
        _dishAvoidText = request.dishAvoids.join(', ');
        _selectedCookingTime = request.cookingTime;
        _selectedDifficulty = request.difficulty;
        _selectedServingSize = request.servingSize;
      }
      _selectedRecipeIds
        ..clear()
        ..addAll(
          showDatabaseResults && plan.topMatches.isNotEmpty
              ? [plan.topMatches.first.id]
              : const <String>[],
        );
    });
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    _isLoading = false;
    _notifyIfActive();
    await loadMealCategories();
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
        (item) => item.name.toLowerCase() == mealType.toLowerCase(),
        orElse: () => categories.isEmpty
            ? const AddMealCategoryOption(id: 'breakfast', name: 'Breakfast')
            : categories.first,
      );
    });
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
        weather: currentPlan.weather,
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
    final currentPlan = _plan;
    final weather =
        currentPlan?.weather ??
        const AddMealWeather(
          temperature: 28,
          condition: 'Any',
          summary: 'No weather data available.',
        );
    final preferences =
        currentPlan?.preferences ??
        const AddMealPreferenceSnapshot(
          diet: 'No Preference',
          allergies: [],
          dislikes: [],
        );
    return AddMealAiGenerationRequest(
      planningDate: selectedDate,
      mealType: _selectedMealCategory?.name ?? mealType,
      weather: weather,
      preferences: AddMealPreferenceSnapshot(
        diet: _selectedMealPreference,
        allergies: preferences.allergies,
        dislikes: preferences.dislikes,
      ),
      ingredientsToInclude: selectedIngredientsToInclude,
      ingredientsToAvoid: selectedIngredientsToAvoid,
      dishIncludes: selectedDishIncludes,
      dishAvoids: selectedDishAvoids,
      cookingTime: _selectedCookingTime,
      difficulty: _selectedDifficulty,
      servingSize: _selectedServingSize,
    );
  }

  void toggleRecipe(String recipeId) {
    if (_selectedRecipeIds.contains(recipeId)) {
      _selectedRecipeIds.remove(recipeId);
    } else {
      _selectedRecipeIds.add(recipeId);
    }
    _notifyIfActive();
  }

  bool isRecipeSelected(String recipeId) {
    return _selectedRecipeIds.contains(recipeId);
  }

  void selectMealPreference(String value) {
    _selectedMealPreference = value;
    _notifyIfActive();
  }

  void updateIngredientIncludeText(String value) {
    _ingredientIncludeText = value;
    _notifyIfActive();
  }

  void updateIngredientAvoidText(String value) {
    _ingredientAvoidText = value;
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

  void selectDifficulty(String value) {
    _selectedDifficulty = value;
    _notifyIfActive();
  }

  void selectServingSize(String value) {
    _selectedServingSize = value;
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

  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
