import '../../domain/entities/meal_plan_dashboard.dart';

class MealPlanDashboardModel extends MealPlanDashboard {
  const MealPlanDashboardModel({
    required super.selectedDate,
    required super.weather,
    required super.summary,
    required super.monthDays,
    required super.sections,
    required super.inspirations,
    required super.quickInspirations,
    required super.groceryLists,
    required super.groceryGroups,
  });

  factory MealPlanDashboardModel.mock() {
    final selectedDate = DateTime.now();

    return MealPlanDashboardModel(
      selectedDate: selectedDate,
      weather: null,
      summary: const MealPlanSummary(
        pastCount: 29,
        todayCount: 3,
        futureCount: 7,
      ),
      monthDays: _buildMonthDays(selectedDate),
      sections: const [
        MealPlanSection(
          mealType: 'Breakfast',
          meals: [
            MealPlanMeal(
              title: 'Sunny Egg & Toast Avocado',
              servingLabel: '2 Serving Pax',
              durationLabel: '30 mins',
              imagePath: 'assets/images/meal1.png',
            ),
            MealPlanMeal(
              title: 'Sunny Egg & Toast Avocado',
              servingLabel: '2 Serving Pax',
              durationLabel: '30 mins',
              imagePath: 'assets/images/meal2.png',
            ),
          ],
        ),
        MealPlanSection(
          mealType: 'Lunch',
          meals: [
            MealPlanMeal(
              title: 'Chicken Quinoa Power Bowl',
              servingLabel: '1 Serving Pax',
              durationLabel: '25 mins',
              imagePath: 'assets/images/meal3.png',
            ),
          ],
        ),
        MealPlanSection(
          mealType: 'Dinner',
          meals: [
            MealPlanMeal(
              title: 'Lemon Garlic Salmon Plate',
              servingLabel: '2 Serving Pax',
              durationLabel: '20 mins',
              imagePath: 'assets/images/meal2.png',
            ),
          ],
        ),
      ],
      inspirations: const [
        MealPlanInspiration(
          title: 'Fresh & Light',
          subtitle: 'Bright bowls for warm weather days.',
          imagePath: 'assets/images/meal3.png',
        ),
        MealPlanInspiration(
          title: 'Protein Breakfast',
          subtitle: 'Simple morning meals that keep you full.',
          imagePath: 'assets/images/meal1.png',
        ),
        MealPlanInspiration(
          title: 'Quick Lunch Prep',
          subtitle: 'Batch-friendly ideas for busy weekdays.',
          imagePath: 'assets/images/meal2.png',
        ),
      ],
      quickInspirations: const [
        MealPlanQuickInspiration(
          title: 'What can I cook with what I have?',
          subtitle: 'Use ingredients you already have.',
          imagePath: 'assets/images/meal3.png',
        ),
        MealPlanQuickInspiration(
          title: 'Surprise me!',
          subtitle: 'Get AI-picked recipes for you.',
          imagePath: 'assets/images/meal2.png',
        ),
        MealPlanQuickInspiration(
          title: 'Healthy Ideas',
          subtitle: 'Nutritious and balanced meals.',
          imagePath: 'assets/images/meal1.png',
        ),
        MealPlanQuickInspiration(
          title: 'Quick & Easy',
          subtitle: 'Recipes you can make in no time.',
          imagePath: 'assets/images/meal3.png',
        ),
        MealPlanQuickInspiration(
          title: 'Rainy Day Comfort',
          subtitle: 'Warm bowls and cozy meal ideas.',
          imagePath: 'assets/images/meal1.png',
        ),
        MealPlanQuickInspiration(
          title: 'High Protein Picks',
          subtitle: 'Filling meals with simple prep.',
          imagePath: 'assets/images/meal2.png',
        ),
      ],
      groceryLists: [
        GroceryListSummary(
          id: 'weekly_groceries',
          title: 'Weekly Groceries',
          itemCount: 18,
          startDate: DateTime(selectedDate.year, selectedDate.month, 1),
          endDate: DateTime(selectedDate.year, selectedDate.month, 7),
          status: GroceryListStatus.active,
          isDefault: true,
          categories: const ['Produce', 'Meat', 'Dairy'],
          extraCategoryCount: 3,
        ),
        GroceryListSummary(
          id: 'healthy_meal_prep',
          title: 'Healthy Meal Prep',
          itemCount: 12,
          startDate: DateTime(selectedDate.year, selectedDate.month, 8),
          endDate: DateTime(selectedDate.year, selectedDate.month, 14),
          status: GroceryListStatus.active,
          categories: const ['Produce', 'Pantry', 'Dairy'],
          extraCategoryCount: 3,
        ),
        GroceryListSummary(
          id: 'weekend_essentials',
          title: 'Weekend Essentials',
          itemCount: 9,
          startDate: DateTime(selectedDate.year, selectedDate.month, 15),
          endDate: DateTime(selectedDate.year, selectedDate.month, 17),
          status: GroceryListStatus.active,
          categories: const ['Produce', 'Snacks', 'Drinks'],
          extraCategoryCount: 3,
        ),
        GroceryListSummary(
          id: 'bbq_party',
          title: 'BBQ Party',
          itemCount: 24,
          startDate: DateTime(selectedDate.year, selectedDate.month, 20),
          endDate: DateTime(selectedDate.year, selectedDate.month, 20),
          status: GroceryListStatus.active,
          categories: const ['Meat', 'Produce', 'Drinks'],
          extraCategoryCount: 3,
        ),
        GroceryListSummary(
          id: 'april_family_meals',
          title: 'April Family Meals',
          itemCount: 16,
          startDate: DateTime(selectedDate.year, selectedDate.month - 1, 8),
          endDate: DateTime(selectedDate.year, selectedDate.month - 1, 14),
          status: GroceryListStatus.past,
          categories: const ['Produce', 'Pantry', 'Dairy'],
          extraCategoryCount: 2,
        ),
        GroceryListSummary(
          id: 'quick_breakfast_run',
          title: 'Quick Breakfast Run',
          itemCount: 7,
          startDate: DateTime(selectedDate.year, selectedDate.month - 1, 22),
          endDate: DateTime(selectedDate.year, selectedDate.month - 1, 22),
          status: GroceryListStatus.past,
          categories: const ['Bakery', 'Fruit', 'Dairy'],
          extraCategoryCount: 1,
        ),
      ],
      groceryGroups: const [
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
      ],
    );
  }

  static List<MealPlanDay> _buildMonthDays(DateTime selectedDate) {
    final firstDay = DateTime(selectedDate.year, selectedDate.month);
    final leadingDays = firstDay.weekday - 1;
    final gridStart = firstDay.subtract(Duration(days: leadingDays));

    return List.generate(35, (index) {
      final date = gridStart.add(Duration(days: index));
      return MealPlanDay(
        date: date,
        isCurrentMonth: date.month == selectedDate.month,
        hasMeals:
            date.day == selectedDate.day && date.month == selectedDate.month,
      );
    });
  }
}

class MealPlanWeatherModel extends MealPlanWeather {
  const MealPlanWeatherModel({
    required super.currentTemp,
    required super.condition,
    required super.summary,
  });
}

class MealPlanPreferenceSummaryModel extends MealPlanPreferenceSummary {
  const MealPlanPreferenceSummaryModel({
    required super.diet,
    required super.allergies,
    required super.dislikes,
  });

  factory MealPlanPreferenceSummaryModel.empty() {
    return const MealPlanPreferenceSummaryModel(
      diet: 'Not set',
      allergies: [],
      dislikes: [],
    );
  }

  factory MealPlanPreferenceSummaryModel.fromJson(Map<String, dynamic> json) {
    return MealPlanPreferenceSummaryModel(
      diet: json['diet']?.toString() ?? 'Not set',
      allergies: _stringList(json['allergies']),
      dislikes: _stringList(json['dislikes']),
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }
}
