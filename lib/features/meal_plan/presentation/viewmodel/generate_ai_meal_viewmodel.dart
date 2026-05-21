import 'package:flutter/foundation.dart';

import '../../../../core/extensions/either_extensions.dart';
import '../../domain/entities/add_meal_ai_plan.dart';
import '../../domain/usecases/get_add_meal_ai_plan_usecase.dart';

class GenerateAiMealViewModel extends ChangeNotifier {
  final GetAddMealAiPlanUseCase _getPlanUseCase;
  final String userId;
  final String mealType;

  AddMealAiPlan? _plan;
  int _currentStep = 1;
  bool _isLoading = true;
  bool _isDisposed = false;
  String? _errorMessage;
  String _selectedMealPreference = 'No Preference';
  String _ingredientIncludeText = '';
  String _ingredientAvoidText = '';
  String _dishIncludeText = '';
  String _dishAvoidText = '';
  String _selectedCookingTime = 'Any';
  String _selectedDifficulty = 'Any';
  String _selectedServingSize = 'Any';
  final Set<String> _selectedRecipeIds = {};

  GenerateAiMealViewModel({
    required this.userId,
    required this.mealType,
    required GetAddMealAiPlanUseCase getPlanUseCase,
  }) : _getPlanUseCase = getPlanUseCase {
    Future.microtask(loadPlan);
  }

  AddMealAiPlan? get plan => _plan;
  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedMealPreference => _selectedMealPreference;
  String get ingredientIncludeText => _ingredientIncludeText;
  String get ingredientAvoidText => _ingredientAvoidText;
  String get dishIncludeText => _dishIncludeText;
  String get dishAvoidText => _dishAvoidText;
  String get selectedCookingTime => _selectedCookingTime;
  String get selectedDifficulty => _selectedDifficulty;
  String get selectedServingSize => _selectedServingSize;
  List<String> get selectedIngredientsToAvoid {
    final values = <String>[
      ...?_plan?.preferences.dislikes,
      if (_ingredientAvoidText.trim().isNotEmpty) _ingredientAvoidText.trim(),
    ];
    return values.toSet().toList();
  }

  List<String> get selectedIngredientsToInclude {
    if (_ingredientIncludeText.trim().isEmpty) return const [];
    return [_ingredientIncludeText.trim()];
  }

  List<String> get selectedDishIncludes {
    if (_dishIncludeText.trim().isEmpty) return const [];
    return [_dishIncludeText.trim()];
  }

  List<String> get selectedDishAvoids {
    if (_dishAvoidText.trim().isEmpty) return const [];
    return [_dishAvoidText.trim()];
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
      _plan = plan;
      _selectedMealPreference = plan.preferences.diet.trim().isEmpty
          ? 'No Preference'
          : plan.preferences.diet;
      _selectedRecipeIds
        ..clear()
        ..add(plan.topMatches.isNotEmpty ? plan.topMatches.first.id : '');
      _selectedRecipeIds.remove('');
    });
    result.ifLeft((failure) {
      _errorMessage = failure.message;
    });

    _isLoading = false;
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
    _currentStep = 2;
    _notifyIfActive();
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

  void selectCookingTime(String value) {
    _selectedCookingTime = value;
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

  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
