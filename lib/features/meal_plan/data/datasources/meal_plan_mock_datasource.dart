import 'package:flutter/material.dart';

import '../models/meal_plan_dashboard_model.dart';
import '../../domain/entities/add_meal_ai_plan.dart';
import '../../domain/entities/add_grocery_list_plan.dart';
import '../../domain/entities/manage_grocery_list_detail.dart';

class MealPlanMockDataSource {
  Future<MealPlanDashboardModel> getDashboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return MealPlanDashboardModel.mock();
  }

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

  Future<AddMealAiPlan> getAddMealAiPlan({
    required String mealType,
    required AddMealPreferenceSnapshot preferences,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    final today = DateTime.now();

    const berryBowl = AddMealAiRecipe(
      id: 'berry_yogurt_bowl',
      title: 'Berry Yogurt Bowl',
      durationLabel: '20 mins',
      difficultyLabel: 'Easy',
      servingLabel: '2 servings',
      imagePath: 'assets/images/meal1.png',
      description: 'Creamy yogurt with fresh berries, granola and honey.',
      reasons: [
        'Light and refreshing for warm weather',
        'High in protein and antioxidants',
        'Quick and easy to prepare',
      ],
      categoryName: 'Breakfast',
    );
    const avocadoToast = AddMealAiRecipe(
      id: 'avocado_egg_toast',
      title: 'Avocado Egg Toast',
      durationLabel: '20 mins',
      difficultyLabel: 'Easy',
      servingLabel: '2 servings',
      imagePath: 'assets/images/meal2.png',
      description: 'Creamy avocado with soft eggs on toasted grain bread.',
      reasons: [
        'Fits vegetarian preferences',
        'Fresh ingredients match sunny weather',
        'Balanced protein and healthy fats',
      ],
      categoryName: 'Breakfast',
    );
    const quinoaBowl = AddMealAiRecipe(
      id: 'quinoa_veggie_bowl',
      title: 'Quinoa Veggie Bowl',
      durationLabel: '25 mins',
      difficultyLabel: 'Easy',
      servingLabel: '2 servings',
      imagePath: 'assets/images/meal3.png',
      description: 'Warm quinoa, grilled vegetables and lemon herb dressing.',
      reasons: [
        'Plant-forward and filling',
        'Avoids common disliked ingredients',
        'Works well for light meal planning',
      ],
      categoryName: 'Main Dish',
    );

    return AddMealAiPlan(
      planningDate: DateTime(today.year, today.month, today.day),
      mealType: mealType,
      weather: const AddMealWeather(
        temperature: 30,
        condition: 'Sunny',
        summary: 'A warm day! Great for fresh & light meals.',
      ),
      preferences: preferences,
      ingredientsToInclude: const ['Eggs', 'Chicken', 'Oats', 'Spinach'],
      ingredientsToAvoid: preferences.dislikes,
      dishPreferences: const ['Dry Meals', 'Rice-Based', 'Noodles', 'Grilled'],
      topMatches: const [berryBowl, avocadoToast],
      aiIdeas: const [berryBowl, avocadoToast, quinoaBowl],
    );
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
