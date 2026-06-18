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

    // Fetch all available meal categories from app configuration.
    final categories = await getMealCategories();

    // Fetch all meal plans for the current month.
    final monthPlans = await _mealPlansBetween(
      userId: userId,
      start: monthStart,
      end: nextMonth,
    );

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

    // Ensure weekly grocery list exists for the user.
    if (userId.trim().isNotEmpty) {
      await ensureCurrentWeeklyGroceryList(userId);
    }

    // Fetch grocery list summaries.
    final groceryLists = await getGroceryListSummaries(userId);

    // Fetch grocery list groups.
    final groceryGroups = await getGroceryGroups(userId);

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
      sections: _buildSections(categories, selectedPlans),
      inspirations: const [],
      quickInspirations: const [],
      groceryLists: groceryLists,
      groceryGroups: groceryGroups,
    );
  }
}
