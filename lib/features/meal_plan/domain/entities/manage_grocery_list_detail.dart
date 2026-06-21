import 'dart:io';

/// Detailed information for managing a grocery list.
/// Contains all data needed for the grocery list management screen.
class ManageGroceryListDetail {
  /// Unique identifier of the grocery list.
  final String id;

  /// Display title of the grocery list.
  final String title;

  /// Total number of items in the list.
  final int itemCount;

  /// Number of meals associated with the list.
  final int mealCount;

  /// Number of categories in the list.
  final int categoryCount;

  /// Start date of the list's date range.
  final DateTime startDate;

  /// End date of the list's date range.
  final DateTime endDate;

  /// List of upcoming meals associated with this list.
  final List<ManageUpcomingMeal> upcomingMeals;

  /// List of categories with their items.
  final List<ManageGroceryCategory> categories;

  /// Timeline of days with their meals.
  final List<ManageGroceryTimelineDay> timelineDays;

  /// Creates a new grocery list detail instance.
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

/// Represents an upcoming meal in the grocery list context.
/// Contains basic meal information for display.
class ManageUpcomingMeal {
  /// Display title of the meal.
  final String title;

  /// Type of meal (e.g., breakfast, lunch, dinner).
  final String mealType;

  /// Date when the meal is scheduled.
  final DateTime date;

  /// Path to the meal's image asset.
  final String imagePath;

  /// Creates a new upcoming meal instance.
  const ManageUpcomingMeal({
    required this.title,
    required this.mealType,
    required this.date,
    required this.imagePath,
  });
}

/// Represents a category of grocery items.
/// Contains a title and list of items in that category.
class ManageGroceryCategory {
  /// Display title of the category.
  final String title;

  /// List of grocery items in this category.
  final List<ManageGroceryItem> items;

  /// Creates a new grocery category instance.
  const ManageGroceryCategory({required this.title, required this.items});
}

/// Represents a single grocery item in the management view.
/// Contains all display information for the item.
class ManageGroceryItem {
  /// Unique identifier of the item.
  final String id;

  /// Display name of the item.
  final String name;

  /// Category ID of the item.
  final String categoryId;

  /// Display name of the category.
  final String categoryName;

  /// Label showing quantity and unit.
  final String quantityLabel;

  /// Emoji icon for the item.
  final String emoji;

  /// Optional ingredient image path.
  final String imagePath;

  /// Whether the item has been bought.
  final bool bought;

  /// Creates a new grocery item instance.
  const ManageGroceryItem({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.quantityLabel,
    required this.emoji,
    this.imagePath = '',
    this.bought = false,
  });
}

/// Represents a day in the grocery list timeline.
/// Contains the date, day number, and meals for that day.
class ManageGroceryTimelineDay {
  /// Date of this timeline day.
  final DateTime date;

  /// Day number (1-based index in the timeline).
  final int dayNumber;

  /// List of meals scheduled for this day.
  final List<ManageGroceryTimelineMeal> meals;

  /// Creates a new timeline day instance.
  const ManageGroceryTimelineDay({
    required this.date,
    required this.dayNumber,
    required this.meals,
  });
}

/// Represents a meal in the grocery list timeline.
/// Contains meal details and associated ingredients.
class ManageGroceryTimelineMeal {
  /// ID of the meal plan.
  final String mealPlanId;

  /// Display title of the meal.
  final String title;

  /// Type of meal (e.g., breakfast, lunch, dinner).
  final String mealType;

  /// Path to the meal's image asset.
  final String imagePath;

  /// List of ingredients needed for this meal.
  final List<ManageGroceryItem> ingredients;

  /// Creates a new timeline meal instance.
  const ManageGroceryTimelineMeal({
    required this.mealPlanId,
    required this.title,
    required this.mealType,
    required this.imagePath,
    required this.ingredients,
  });
}

/// Request object for adding a grocery item.
/// Contains all parameters needed to create a new grocery item.
class AddGroceryItemRequest {
  /// ID of the grocery list to add the item to.
  final String listId;

  /// Name of the grocery item.
  final String name;

  /// Quantity amount of the item.
  final double amount;

  /// Unit of measurement for the quantity.
  final String unit;

  /// ID of the selected configured unit.
  final String unitId;

  /// Custom unit text when no configured unit is selected.
  final String customUnit;

  /// Optional ingredient image file.
  final File? imageFile;

  /// List of meal plan IDs associated with this item.
  final List<String> relatedMealPlanIds;

  /// Creates a new add grocery item request.
  const AddGroceryItemRequest({
    required this.listId,
    required this.name,
    required this.amount,
    required this.unit,
    this.unitId = '',
    this.customUnit = '',
    this.imageFile,
    this.relatedMealPlanIds = const [],
  });
}
