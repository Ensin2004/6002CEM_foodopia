import 'package:flutter/material.dart';

import '../../domain/entities/add_grocery_list_plan.dart';
import '../../domain/entities/manage_grocery_list_detail.dart';
import '../../domain/entities/meal_plan_dashboard.dart';

class MealPlanMockDataSource {
  Future<AddGroceryListPlan> getAddGroceryListPlan() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);

    return AddGroceryListPlan(
      iconOptions: const [
        GroceryIconOption(id: 'basket', icon: Icons.shopping_basket_outlined),
        GroceryIconOption(id: 'bag', icon: Icons.shopping_bag_outlined),
        GroceryIconOption(id: 'carrot', icon: Icons.emoji_food_beverage),
        GroceryIconOption(id: 'apple', icon: Icons.apple),
        GroceryIconOption(id: 'bottle', icon: Icons.local_drink_outlined),
        GroceryIconOption(id: 'protein', icon: Icons.set_meal_outlined),
        GroceryIconOption(id: 'bakery', icon: Icons.bakery_dining_outlined),
      ],
      mealDays: List.generate(6, (index) {
        final date = start.add(Duration(days: index));
        return GroceryMealDayPlan(
          date: date,
          sections: [
            GroceryMealSectionPlan(
              title: 'Breakfast',
              meals: [
                GroceryMealPlanItem(
                  id: 'breakfast_${index}_egg',
                  title: 'Sunny Egg & Toast Avocado',
                  imagePath: 'assets/images/meal1.png',
                ),
                GroceryMealPlanItem(
                  id: 'breakfast_${index}_burger',
                  title: 'Burger with Salmon',
                  imagePath: 'assets/images/meal2.png',
                ),
              ],
            ),
            GroceryMealSectionPlan(
              title: 'Lunch',
              meals: [
                GroceryMealPlanItem(
                  id: 'lunch_${index}_carbonara',
                  title: 'Carbonara with Shredded Chicken',
                  imagePath: 'assets/images/meal3.png',
                ),
              ],
            ),
          ],
        );
      }),
    );
  }

  Future<List<GroceryListSummary>> getGroceryListSummaries() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final today = DateTime.now();
    return [
      GroceryListSummary(
        id: 'weekly_groceries',
        title: 'Weekly Groceries',
        itemCount: 18,
        startDate: DateTime(today.year, today.month, 1),
        endDate: DateTime(today.year, today.month, 7),
        status: GroceryListStatus.active,
        isDefault: true,
        categories: const ['Produce', 'Meat', 'Dairy'],
        extraCategoryCount: 3,
      ),
      GroceryListSummary(
        id: 'healthy_meal_prep',
        title: 'Healthy Meal Prep',
        itemCount: 12,
        startDate: DateTime(today.year, today.month, 8),
        endDate: DateTime(today.year, today.month, 14),
        status: GroceryListStatus.active,
        categories: const ['Produce', 'Pantry', 'Dairy'],
        extraCategoryCount: 3,
      ),
      GroceryListSummary(
        id: 'weekend_essentials',
        title: 'Weekend Essentials',
        itemCount: 9,
        startDate: DateTime(today.year, today.month, 15),
        endDate: DateTime(today.year, today.month, 17),
        status: GroceryListStatus.active,
        categories: const ['Produce', 'Snacks', 'Drinks'],
        extraCategoryCount: 3,
      ),
      GroceryListSummary(
        id: 'bbq_party',
        title: 'BBQ Party',
        itemCount: 24,
        startDate: DateTime(today.year, today.month, 20),
        endDate: DateTime(today.year, today.month, 20),
        status: GroceryListStatus.active,
        categories: const ['Meat', 'Produce', 'Drinks'],
        extraCategoryCount: 3,
      ),
      GroceryListSummary(
        id: 'april_family_meals',
        title: 'April Family Meals',
        itemCount: 16,
        startDate: DateTime(today.year, today.month - 1, 8),
        endDate: DateTime(today.year, today.month - 1, 14),
        status: GroceryListStatus.past,
        categories: const ['Produce', 'Pantry', 'Dairy'],
        extraCategoryCount: 2,
      ),
      GroceryListSummary(
        id: 'quick_breakfast_run',
        title: 'Quick Breakfast Run',
        itemCount: 7,
        startDate: DateTime(today.year, today.month - 1, 22),
        endDate: DateTime(today.year, today.month - 1, 22),
        status: GroceryListStatus.past,
        categories: const ['Bakery', 'Fruit', 'Dairy'],
        extraCategoryCount: 1,
      ),
    ];
  }

  List<GroceryListGroup> getGroceryGroups() {
    return const [
      GroceryListGroup(
        title: 'Produce',
        items: ['Avocado', 'Cherry tomatoes', 'Lettuce', 'Lemon'],
      ),
      GroceryListGroup(
        title: 'Protein',
        items: ['Eggs', 'Chicken breast', 'Salmon fillet'],
      ),
      GroceryListGroup(
        title: 'Pantry',
        items: ['Wholegrain bread', 'Quinoa', 'Olive oil'],
      ),
    ];
  }

  Future<ManageGroceryListDetail> getManageGroceryListDetail(
    String listId,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);

    const dairyItems = [
      ManageGroceryItem(
        id: 'eggs',
        name: 'Organic Fresh Eggs',
        quantityLabel: '3 items',
        emoji: '🥚',
      ),
      ManageGroceryItem(
        id: 'milk',
        name: 'Full Cream Milk',
        quantityLabel: '3 items',
        emoji: '🥛',
      ),
      ManageGroceryItem(
        id: 'cheese',
        name: 'Mozzarella Block Cheese',
        quantityLabel: '3 items',
        emoji: '🧀',
      ),
    ];
    const fruitItems = [
      ManageGroceryItem(
        id: 'avocado',
        name: 'Avocado',
        quantityLabel: 'x 1',
        emoji: '🥑',
      ),
      ManageGroceryItem(
        id: 'greens',
        name: 'xxx',
        quantityLabel: 'x 1',
        emoji: '🥗',
      ),
      ManageGroceryItem(
        id: 'herbs',
        name: 'xxx',
        quantityLabel: 'x 1',
        emoji: '🥗',
      ),
    ];

    final timelineMeals = [
      ManageGroceryTimelineMeal(
        title: 'Sunny Egg & Toast Avocado',
        mealType: 'Breakfast',
        imagePath: 'assets/images/meal1.png',
        ingredients: fruitItems,
      ),
      ManageGroceryTimelineMeal(
        title: 'Chicken Salad',
        mealType: 'Dinner',
        imagePath: 'assets/images/meal2.png',
        ingredients: fruitItems,
      ),
    ];

    return ManageGroceryListDetail(
      id: listId,
      title: _titleForList(listId),
      itemCount: 18,
      mealCount: 2,
      categoryCount: 6,
      startDate: start,
      endDate: start.add(const Duration(days: 1)),
      upcomingMeals: [
        ManageUpcomingMeal(
          title: 'Sunny Egg & Toast Avocado',
          mealType: 'Breakfast',
          date: start,
          imagePath: 'assets/images/meal1.png',
        ),
        ManageUpcomingMeal(
          title: 'Sunny Egg & Toast Avocado',
          mealType: 'Breakfast',
          date: start,
          imagePath: 'assets/images/meal1.png',
        ),
      ],
      categories: const [
        ManageGroceryCategory(title: 'Dairy', items: dairyItems),
        ManageGroceryCategory(title: 'Fruit', items: fruitItems),
      ],
      timelineDays: [
        ManageGroceryTimelineDay(
          date: start,
          dayNumber: 1,
          meals: timelineMeals,
        ),
        ManageGroceryTimelineDay(
          date: start.add(const Duration(days: 1)),
          dayNumber: 2,
          meals: timelineMeals,
        ),
      ],
    );
  }

  String _titleForList(String listId) {
    switch (listId) {
      case 'healthy_meal_prep':
        return 'Healthy Meal Prep';
      case 'weekend_essentials':
        return 'Weekend Essentials';
      case 'bbq_party':
        return 'BBQ Party';
      default:
        return 'Weekly Groceries';
    }
  }
}
