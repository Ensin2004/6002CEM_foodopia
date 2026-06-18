part of '../meal_plan_viewmodel.dart';

/// Inspiration inputs, ingredient search, and preference override actions.
mixin _MealPlanInspirationViewModelMixin
    on _MealPlanViewModelBase, _MealPlanViewModelHelpers {
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
      targetCalories: _preferences?.targetCalories,
      calorieUnit: _preferences?.calorieUnit ?? 'kcal',
      calorieTargetEnabled: _preferences?.calorieTargetEnabled ?? false,
    );
  }

  /// Loads inspiration input options.
  Future<void> loadInspirationInputs() async {
    // Each preference group uses the same options use case.
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

  /// Searches for ingredients.
  Future<void> searchIngredients(String query) async {
    // Short queries clear the result list.
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

  /// Searches for preference foods.
  Future<void> searchPreferenceFoods(String query) async {
    // Short queries clear the result list.
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

  /// Toggles an ingredient selection.
  void toggleIngredient(MealPlanInspirationIngredient ingredient) {
    // Match ingredients by case-insensitive name.
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

  /// Adds a custom ingredient.
  void addCustomIngredient(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    // Custom ingredients use stable IDs derived from names.
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

    // Custom value replaces the neutral "None" selection.
    _overrideAllergies.remove('None');

    if (!_overrideAllergies.contains(trimmed)) {
      _overrideAllergies.add(trimmed);
    }

    _notifyIfActive();
  }

  /// Adds a custom override dislike.
  void addCustomOverrideDislike(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    // Custom value replaces the neutral "None" selection.
    _overrideDislikes.remove('None');

    if (!_overrideDislikes.contains(trimmed)) {
      _overrideDislikes.add(trimmed);
    }

    _notifyIfActive();
  }
}
