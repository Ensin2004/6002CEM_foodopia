class ManageGroceryListDetail {
  final String id;
  final String title;
  final int itemCount;
  final int mealCount;
  final int categoryCount;
  final DateTime startDate;
  final DateTime endDate;
  final List<ManageUpcomingMeal> upcomingMeals;
  final List<ManageGroceryCategory> categories;
  final List<ManageGroceryTimelineDay> timelineDays;

  const ManageGroceryListDetail({
    required this.id,
    required this.title,
    required this.itemCount,
    required this.mealCount,
    required this.categoryCount,
    required this.startDate,
    required this.endDate,
    required this.upcomingMeals,
    required this.categories,
    required this.timelineDays,
  });
}

class ManageUpcomingMeal {
  final String title;
  final String mealType;
  final DateTime date;
  final String imagePath;

  const ManageUpcomingMeal({
    required this.title,
    required this.mealType,
    required this.date,
    required this.imagePath,
  });
}

class ManageGroceryCategory {
  final String title;
  final List<ManageGroceryItem> items;

  const ManageGroceryCategory({required this.title, required this.items});
}

class ManageGroceryItem {
  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final String quantityLabel;
  final String emoji;
  final bool bought;

  const ManageGroceryItem({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.quantityLabel,
    required this.emoji,
    this.bought = false,
  });
}

class ManageGroceryTimelineDay {
  final DateTime date;
  final int dayNumber;
  final List<ManageGroceryTimelineMeal> meals;

  const ManageGroceryTimelineDay({
    required this.date,
    required this.dayNumber,
    required this.meals,
  });
}

class ManageGroceryTimelineMeal {
  final String mealPlanId;
  final String title;
  final String mealType;
  final String imagePath;
  final List<ManageGroceryItem> ingredients;

  const ManageGroceryTimelineMeal({
    required this.mealPlanId,
    required this.title,
    required this.mealType,
    required this.imagePath,
    required this.ingredients,
  });
}

class AddGroceryItemRequest {
  final String listId;
  final String name;
  final double amount;
  final String unit;
  final String categoryName;
  final List<String> relatedMealPlanIds;

  const AddGroceryItemRequest({
    required this.listId,
    required this.name,
    required this.amount,
    required this.unit,
    required this.categoryName,
    this.relatedMealPlanIds = const [],
  });
}
