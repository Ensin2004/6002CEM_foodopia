import 'package:flutter/material.dart';

class UserHomeDashboard {
  final String userName;
  final String greeting;
  final UserHomeWeather? weather;
  final List<UserHomeQuickLink> quickLinks;
  final List<UserHomeMealSection> mealPlan;

  const UserHomeDashboard({
    required this.userName,
    required this.greeting,
    required this.weather,
    required this.quickLinks,
    required this.mealPlan,
  });

  UserHomeDashboard copyWith({UserHomeWeather? weather}) {
    return UserHomeDashboard(
      userName: userName,
      greeting: greeting,
      weather: weather ?? this.weather,
      quickLinks: quickLinks,
      mealPlan: mealPlan,
    );
  }
}

class UserHomeWeather {
  final int currentTemp;
  final int minTemp;
  final int maxTemp;
  final String condition;
  final String summary;
  final int humidity;
  final int windSpeed;
  final String uvIndex;

  const UserHomeWeather({
    required this.currentTemp,
    required this.minTemp,
    required this.maxTemp,
    required this.condition,
    required this.summary,
    required this.humidity,
    required this.windSpeed,
    required this.uvIndex,
  });
}

enum UserHomeQuickLinkTarget {
  explore,
  addRecipe,
  mealPlan,
  tryAi,
  groceryList,
  statistics,
}

class UserHomeQuickLink {
  final String title;
  final IconData icon;
  final UserHomeQuickLinkTarget target;

  const UserHomeQuickLink({
    required this.title,
    required this.icon,
    required this.target,
  });
}

class UserHomeMealSection {
  final String mealType;
  final String countLabel;
  final Color accentColor;
  final IconData icon;
  final List<UserHomeMeal> meals;

  const UserHomeMealSection({
    required this.mealType,
    required this.countLabel,
    required this.accentColor,
    required this.icon,
    required this.meals,
  });
}

class UserHomeMeal {
  final String title;
  final String subtitle;
  final String duration;
  final String imagePath;

  const UserHomeMeal({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.imagePath,
  });
}
