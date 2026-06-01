class GroceryListStatistics {
  final String dateRange;
  final int totalGroceryLists;
  final String mostGroceryListMonth;
  final List<GroceryListMonthStatistic> months;

  const GroceryListStatistics({
    required this.dateRange,
    required this.totalGroceryLists,
    required this.mostGroceryListMonth,
    required this.months,
  });
}

class GroceryListMonthStatistic {
  final DateTime month;
  final String label;
  final int totalLists;
  final List<GroceryListStatisticItem> lists;

  const GroceryListMonthStatistic({
    required this.month,
    required this.label,
    required this.totalLists,
    required this.lists,
  });
}

class GroceryListStatisticItem {
  final String name;
  final String duration;
  final DateTime createdAt;

  const GroceryListStatisticItem({
    required this.name,
    required this.duration,
    required this.createdAt,
  });
}
