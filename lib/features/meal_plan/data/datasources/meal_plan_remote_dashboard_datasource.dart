part of 'meal_plan_remote_datasource.dart';

/// Dashboard-specific remote operations for meal planning.
mixin _MealPlanRemoteDashboardDataSource
    on
        _MealPlanRemoteDataSourceCore,
        _MealPlanRemoteDataSourceHelpers,
        _MealPlanRemoteOperationsDataSource,
        _MealPlanRemoteGroceryDataSource {
  // =========================================================================
  // DASHBOARD
  // =========================================================================

  /// Retrieves the meal plan dashboard for a specific user and date.
  /// Fetches meal plans, grocery lists, and generates calendar data.
  Future<MealPlanDashboard> getDashboard({
    required String userId,
    required DateTime selectedDate,
  }) async {
    // Month-level query feeds both the selected date sections and calendar dots.
    final dayStart = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    // Start of the month for range queries.
    final monthStart = DateTime(selectedDate.year, selectedDate.month);

    // Start of the next month for range end.
    final nextMonth = DateTime(selectedDate.year, selectedDate.month + 1);

    // Start independent dashboard queries together.
    final categoriesFuture = getMealCategories();
    final monthPlansFuture = _mealPlansBetween(
      userId: userId,
      start: monthStart,
      end: nextMonth,
    );
    final groceryListsFuture = getGroceryListSummaries(userId);
    final groceryGroupsFuture = getGroceryGroups(userId);

    // Weekly list creation is best-effort and should not block planning.
    if (userId.trim().isNotEmpty) {
      unawaited(
        ensureCurrentWeeklyGroceryList(userId).catchError((Object error) {
          debugPrint('[MealPlan] Weekly grocery sync skipped: $error');
        }),
      );
    }

    // Fetch meal categories and monthly plans.
    final categories = await categoriesFuture;
    final monthPlans = await monthPlansFuture;

    // Filter plans that fall on the selected date.
    final selectedPlans = monthPlans.where((doc) {
      final value = doc.data()['date'];
      return value is Timestamp && _sameDay(value.toDate(), dayStart);
    }).toList();

    // Get today's date without time component for comparison.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Count meal plans from past dates.
    final pastCount = monthPlans.where((doc) {
      final value = doc.data()['date'];
      return value is Timestamp && value.toDate().isBefore(today);
    }).length;

    // Count meal plans for today.
    final todayCount = monthPlans.where((doc) {
      final value = doc.data()['date'];
      return value is Timestamp && _sameDay(value.toDate(), today);
    }).length;

    // Count meal plans for future dates.
    final futureCount = monthPlans.where((doc) {
      final value = doc.data()['date'];
      return value is Timestamp && value.toDate().isAfter(today);
    }).length;

    // Build sections after resolving recipe/AI display data.
    final sections = await _buildSections(categories, selectedPlans);
    final groceryLists = await groceryListsFuture;
    final groceryGroups = await groceryGroupsFuture;

    // Build and return the complete dashboard object.
    return MealPlanDashboard(
      selectedDate: dayStart,
      weather: null,
      summary: MealPlanSummary(
        pastCount: pastCount,
        todayCount: todayCount,
        futureCount: futureCount,
      ),
      monthDays: _buildMonthDays(dayStart, monthPlans),
      sections: sections,
      inspirations: const [],
      quickInspirations: const [],
      groceryLists: groceryLists,
      groceryGroups: groceryGroups,
    );
  }

  /// Retrieves only the planning data for a specific user and date.
  /// Skips grocery and side-panel queries so returning from add-meal is fast.
  Future<MealPlanDashboard> getPlanningDashboard({
    required String userId,
    required DateTime selectedDate,
  }) async {
    final dayStart = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final monthStart = DateTime(selectedDate.year, selectedDate.month);
    final nextMonth = DateTime(selectedDate.year, selectedDate.month + 1);

    final categoriesFuture = getMealCategories();
    final monthPlansFuture = _mealPlansBetween(
      userId: userId,
      start: monthStart,
      end: nextMonth,
    );

    final categories = await categoriesFuture;
    final monthPlans = await monthPlansFuture;

    final selectedPlans = monthPlans.where((doc) {
      final value = doc.data()['date'];
      return value is Timestamp && _sameDay(value.toDate(), dayStart);
    }).toList();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final pastCount = monthPlans.where((doc) {
      final value = doc.data()['date'];
      return value is Timestamp && value.toDate().isBefore(today);
    }).length;

    final todayCount = monthPlans.where((doc) {
      final value = doc.data()['date'];
      return value is Timestamp && _sameDay(value.toDate(), today);
    }).length;

    final futureCount = monthPlans.where((doc) {
      final value = doc.data()['date'];
      return value is Timestamp && value.toDate().isAfter(today);
    }).length;

    return MealPlanDashboard(
      selectedDate: dayStart,
      weather: null,
      summary: MealPlanSummary(
        pastCount: pastCount,
        todayCount: todayCount,
        futureCount: futureCount,
      ),
      monthDays: _buildMonthDays(dayStart, monthPlans),
      sections: await _buildSections(categories, selectedPlans),
      inspirations: const [],
      quickInspirations: const [],
      groceryLists: const [],
      groceryGroups: const [],
    );
  }
}
