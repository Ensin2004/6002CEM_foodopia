part of '../meal_plan_viewmodel.dart';

/// Grocery tab state, filters, and weekly list actions.
mixin _MealPlanGroceryViewModelMixin
    on
        _MealPlanViewModelBase,
        _MealPlanViewModelHelpers,
        _MealPlanDashboardViewModelMixin {
  /// Filtered grocery lists based on tab and search query.
  List<GroceryListSummary> get filteredGroceryLists {
    // Dashboard grocery lists are filtered for the active tab.
    final lists = _dashboard?.groceryLists ?? const <GroceryListSummary>[];

    final status = _selectedGroceryListTab == GroceryListTabFilter.active
        ? GroceryListStatus.active
        : GroceryListStatus.past;

    final query = _grocerySearchQuery.trim().toLowerCase();

    return lists.where((list) {
      if (list.status != status) return false;
      if (query.isEmpty) return true;

      // Title, date, category, and week start day are searchable.
      final dateText = '${list.startDate} ${list.endDate}'.toLowerCase();
      final categoryText = list.categories.join(' ').toLowerCase();

      return list.title.toLowerCase().contains(query) ||
          categoryText.contains(query) ||
          dateText.contains(query) ||
          list.weekStartDay.toLowerCase().contains(query);
    }).toList();
  }

  /// Current weekly grocery list.
  GroceryListSummary? get currentWeeklyGroceryList {
    // Active weekly list is shown as the primary grocery card.
    final lists = _dashboard?.groceryLists ?? const <GroceryListSummary>[];

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
    final weeklyLists = filteredGroceryLists
        .where((list) => list.isWeekly)
        .toList();
    final uniqueByWeek = <String, GroceryListSummary>{};

    for (final list in weeklyLists) {
      final key =
          '${list.status.name}-'
          '${_dateKey(list.startDate)}-'
          '${_dateKey(list.endDate)}';
      uniqueByWeek.putIfAbsent(key, () => list);
    }

    return uniqueByWeek.values.toList();
  }

  String _dateKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String();
  }

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
    // Clear any previous grocery action error.
    _groceryActionErrorMessage = null;
    _notifyIfActive();

    final result = await _updateWeeklyGroceryWeekStartDayUseCase.execute(
      userId: userId,
      weekStartDay: weekStartDay,
    );

    if (_isDisposed) return;

    result.ifLeft((failure) {
      _groceryActionErrorMessage = failure.message;
    });
    result.ifRight((_) {
      _groceryActionErrorMessage = null;
    });

    await loadDashboard();
  }
}
