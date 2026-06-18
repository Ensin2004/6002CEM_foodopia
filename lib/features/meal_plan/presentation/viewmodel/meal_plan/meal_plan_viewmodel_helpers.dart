part of '../meal_plan_viewmodel.dart';

/// Shared private helpers for meal plan viewmodel mixins.
mixin _MealPlanViewModelHelpers on _MealPlanViewModelBase {
  /// Replaces values in a list with a source list.
  void _replaceValues(List<String> target, List<String> source) {
    target
      ..clear()
      ..addAll(source);
  }

  /// Toggles a value in a list.
  void _toggleValue(List<String> values, String value) {
    // "None" acts as a single exclusive selection.
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

    // Any real value removes the neutral "None" selection.
    values.remove('None');

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
    // Existing option names are matched case-insensitively.
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

  /// Returns a filter ID for a section.
  String _filterIdForSection(MealPlanSection section) {
    // Category ID is preferred when available.
    final categoryId = section.mealCategoryId.trim();
    if (categoryId.isNotEmpty) return categoryId;

    // Meal type becomes a stable fallback key.
    return section.mealType.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      '_',
    );
  }

  /// Normalizes the selected filter.
  void _normalizeSelectedFilter() {
    // The all filter is always valid.
    if (_selectedFilterId == MealPlanViewModel.allFilterId) return;

    final sections = _dashboard?.sections ?? const <MealPlanSection>[];

    final exists = sections.any(
      (section) => _filterIdForSection(section) == _selectedFilterId,
    );

    if (!exists) _selectedFilterId = MealPlanViewModel.allFilterId;
  }

  /// Removes a meal from the dashboard.
  void _removeMealFromDashboard(String mealPlanId) {
    // Local dashboard update keeps the UI responsive after delete success.
    final current = _dashboard;
    if (current == null) return;

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

    if (!removed) return;

    final hasMealsForSelectedDate = sections.any(
      (section) => section.meals.isNotEmpty,
    );

    final monthDays = current.monthDays.map((day) {
      if (!_sameDay(day.date, current.selectedDate)) return day;
      return MealPlanDay(
        date: day.date,
        isCurrentMonth: day.isCurrentMonth,
        hasMeals: hasMealsForSelectedDate,
      );
    }).toList();

    _dashboard = current.copyWith(
      sections: sections,
      monthDays: monthDays,
      summary: _decrementSummary(current.summary, current.selectedDate),
    );

    _normalizeSelectedFilter();
    _notifyIfActive();
  }

  /// Decrements a summary count for a date.
  MealPlanSummary _decrementSummary(MealPlanSummary summary, DateTime date) {
    // Date comparison ignores time.
    final day = DateTime(date.year, date.month, date.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

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

  /// Notifies listeners if the ViewModel is still active.
  void _notifyIfActive() {
    if (!_isDisposed) notifyListeners();
  }
}
