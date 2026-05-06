import '../../domain/entities/meal_plan_dashboard.dart';

class MealPlanDashboardModel extends MealPlanDashboard {
  const MealPlanDashboardModel({
    required super.selectedDate,
    required super.weather,
    required super.summary,
    required super.monthDays,
    required super.sections,
    required super.inspirations,
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
