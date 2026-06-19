part of '../meal_plan_viewmodel.dart';

/// Dashboard, filter, weather, and meal actions.
mixin _MealPlanDashboardViewModelMixin
    on
        _MealPlanViewModelBase,
        _MealPlanViewModelHelpers,
        _MealPlanInspirationViewModelMixin {
  /// Filtered meal sections based on selected filter.
  List<MealPlanSection> get filteredSections {
    // Dashboard sections are the source for planning cards.
    final sections = _dashboard?.sections ?? const <MealPlanSection>[];

    // "All" keeps every section visible.
    if (_selectedFilterId == MealPlanViewModel.allFilterId) return sections;

    // Category-specific filters use the section filter ID.
    return sections
        .where((section) => _filterIdForSection(section) == _selectedFilterId)
        .toList();
  }

  /// Filter options for meal sections.
  List<MealPlanFilterOption> get filterOptions {
    // Dashboard sections provide labels and counts.
    final sections = _dashboard?.sections ?? const <MealPlanSection>[];

    // Total meal count powers the "All" tab badge.
    final totalCount = sections.fold<int>(
      0,
      (count, section) => count + section.meals.length,
    );

    return [
      MealPlanFilterOption(
        id: MealPlanViewModel.allFilterId,
        label: 'All',
        count: totalCount,
      ),
      ...sections.map(
        (section) => MealPlanFilterOption(
          id: _filterIdForSection(section),
          label: section.mealType,
          count: section.meals.length,
        ),
      ),
    ];
  }

  /// Selects a meal filter.
  void selectFilter(String filterId) {
    if (_selectedFilterId == filterId) return;
    _selectedFilterId = filterId;
    _notifyIfActive();
  }

  /// Deletes a meal plan.
  Future<bool> deleteMealPlan(String mealPlanId) async {
    // Empty IDs cannot be sent to the delete use case.
    final trimmedId = mealPlanId.trim();
    if (trimmedId.isEmpty) {
      _mealActionErrorMessage = 'Meal plan is missing.';
      _notifyIfActive();
      return false;
    }

    // Clear previous action error before executing.
    _mealActionErrorMessage = null;
    _notifyIfActive();

    final result = await _deleteMealPlanUseCase.execute(
      userId: userId,
      mealPlanId: trimmedId,
    );

    if (_isDisposed) return false;

    // Delete result controls local optimistic cleanup.
    var deleted = false;
    result.ifRight((_) => deleted = true);
    result.ifLeft((failure) => _mealActionErrorMessage = failure.message);

    _notifyIfActive();

    if (deleted) {
      _removeMealFromDashboard(trimmedId);
      unawaited(loadDashboard());
    }

    return deleted;
  }

  /// Loads the meal plan dashboard.
  Future<void> loadDashboard() async {
    // Keep existing dashboard visible while refreshing selected-day meals.
    _isLoading = true;
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

    // Related side data should not block showing the selected day's meals.
    unawaited(refreshWeather());
    if (_preferences == null) unawaited(loadPreferences());
    unawaited(loadInspirationInputs());
  }

  /// Selects a date and reloads the dashboard.
  Future<void> selectDate(DateTime date) async {
    _selectedDate = DateTime(date.year, date.month, date.day);
    final currentDashboard = _dashboard;
    if (currentDashboard != null) {
      _isLoading = true;
      _dashboard = currentDashboard.copyWith(
        selectedDate: _selectedDate,
        sections: const <MealPlanSection>[],
      );
      _normalizeSelectedFilter();
      _notifyIfActive();
    }
    await loadDashboard();
  }

  /// Loads user preferences.
  Future<void> loadPreferences() async {
    // Preference loading is separate from dashboard loading.
    _isPreferencesLoading = true;
    _preferencesErrorMessage = null;
    _notifyIfActive();

    try {
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
        _preferences = _emptyPreferences;
        _preferencesErrorMessage = failure.message;
      });
    } catch (error) {
      _preferences = _emptyPreferences;
      _preferencesErrorMessage = error.toString();
    } finally {
      if (!_isDisposed) {
        _isPreferencesLoading = false;
        _notifyIfActive();
      }
    }
  }

  /// Empty preferences used when no saved target/profile exists.
  MealPlanPreferenceSummary get _emptyPreferences {
    return const MealPlanPreferenceSummary(
      diet: 'Not set',
      allergies: [],
      dislikes: [],
      targetCalories: null,
      calorieUnit: 'kcal',
      calorieTargetEnabled: false,
    );
  }

  /// Refreshes the weather data.
  Future<void> refreshWeather() async {
    // Weather needs an existing selected dashboard date.
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

  /// Selects a weather category.
  void selectWeatherCategory(String id) {
    _selectedWeatherCategoryId = id;
    _notifyIfActive();
  }
}
