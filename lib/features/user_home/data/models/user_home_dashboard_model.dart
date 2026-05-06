import 'package:flutter/material.dart';

import '../../domain/entities/user_home_dashboard.dart';

class UserHomeDashboardModel extends UserHomeDashboard {
  const UserHomeDashboardModel({
    required super.userName,
    required super.greeting,
    required super.weather,
    required super.quickLinks,
    required super.mealPlan,
  });

  factory UserHomeDashboardModel.mock(String userName) {
    return UserHomeDashboardModel(
      userName: userName,
      greeting: 'Good afternoon',
      weather: null,
      quickLinks: const [
        UserHomeQuickLink(
          title: 'Explore Recipes',
          icon: Icons.search,
          target: UserHomeQuickLinkTarget.explore,
        ),
        UserHomeQuickLink(
          title: 'Add Recipe',
          icon: Icons.add_circle_outline,
          target: UserHomeQuickLinkTarget.addRecipe,
        ),
        UserHomeQuickLink(
          title: 'Plan Meal',
          icon: Icons.event_note,
          target: UserHomeQuickLinkTarget.mealPlan,
        ),
        UserHomeQuickLink(
          title: 'Try AI',
          icon: Icons.auto_awesome,
          target: UserHomeQuickLinkTarget.tryAi,
        ),
        UserHomeQuickLink(
          title: 'Grocery List',
          icon: Icons.shopping_cart_outlined,
          target: UserHomeQuickLinkTarget.groceryList,
        ),
        UserHomeQuickLink(
          title: 'Statistics',
          icon: Icons.bar_chart,
          target: UserHomeQuickLinkTarget.statistics,
        ),
      ],
      mealPlan: const [
        UserHomeMealSection(
          mealType: 'Breakfast',
          countLabel: 'Total 2 meals',
          accentColor: Color(0xFFFFF7E1),
          icon: Icons.wb_sunny_outlined,
          meals: [
            UserHomeMeal(
              title: 'Overnight Oats with Berries',
              subtitle: 'High Fiber',
              duration: '10 min',
              imagePath: 'assets/images/meal1.png',
            ),
            UserHomeMeal(
              title: 'Avocado & Egg Toast',
              subtitle: 'High Protein',
              duration: '15 min',
              imagePath: 'assets/images/meal2.png',
            ),
          ],
        ),
        UserHomeMealSection(
          mealType: 'Lunch',
          countLabel: 'Total 1 meal',
          accentColor: Color(0xFFEFF8F1),
          icon: Icons.eco_outlined,
          meals: [
            UserHomeMeal(
              title: 'Quinoa Chicken Salad Bowl',
              subtitle: 'High Protein',
              duration: '25 min',
              imagePath: 'assets/images/meal3.png',
            ),
          ],
        ),
        UserHomeMealSection(
          mealType: 'Dinner',
          countLabel: 'Total 1 meal',
          accentColor: Color(0xFFFFF0E7),
          icon: Icons.nightlight_outlined,
          meals: [
            UserHomeMeal(
              title: 'Lemon Garlic Salmon',
              subtitle: 'High Protein',
              duration: '20 min',
              imagePath: 'assets/images/meal2.png',
            ),
          ],
        ),
        UserHomeMealSection(
          mealType: 'Snack',
          countLabel: 'Total 1 meal',
          accentColor: Color(0xFFF2EEFF),
          icon: Icons.local_drink_outlined,
          meals: [
            UserHomeMeal(
              title: 'Green Smoothie with Spinach',
              subtitle: 'High Fiber',
              duration: '5 min',
              imagePath: 'assets/images/meal1.png',
            ),
          ],
        ),
      ],
    );
  }
}

class UserHomeWeatherModel extends UserHomeWeather {
  const UserHomeWeatherModel({
    required super.currentTemp,
    required super.minTemp,
    required super.maxTemp,
    required super.condition,
    required super.summary,
    required super.humidity,
    required super.windSpeed,
    required super.uvIndex,
  });
}
