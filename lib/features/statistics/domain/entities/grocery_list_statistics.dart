// These notes explain the statistics page code in simple words.
// Only comments were added here; the code behaviour stays the same.
// Handles GroceryListStatistics for this part of the statistics page.
class GroceryListStatistics {
  final String dateRange;
  final int totalGroceryLists;
  final String mostGroceryListMonth;
  final List<GroceryListMonthStatistic> months;

  // Handles GroceryListStatistics for this part of the statistics page.
  const GroceryListStatistics({
    required this.dateRange,
    required this.totalGroceryLists,
    required this.mostGroceryListMonth,
    required this.months,
  });
}

// Handles GroceryListMonthStatistic for this part of the statistics page.
class GroceryListMonthStatistic {
  final DateTime month;
  final String label;
  final int totalLists;
  final List<GroceryListStatisticItem> lists;

  // Handles GroceryListMonthStatistic for this part of the statistics page.
  const GroceryListMonthStatistic({
    required this.month,
    required this.label,
    required this.totalLists,
    required this.lists,
  });
}

// Handles GroceryListStatisticItem for this part of the statistics page.
class GroceryListStatisticItem {
  final String name;
  final String duration;
  final DateTime createdAt;

  // Handles GroceryListStatisticItem for this part of the statistics page.
  const GroceryListStatisticItem({
    required this.name,
    required this.duration,
    required this.createdAt,
  });
}
