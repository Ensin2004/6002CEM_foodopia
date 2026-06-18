import 'package:flutter/material.dart';

/// Main dashboard entity for the user home screen.
/// Contains user information, weather, quick links, and meal sections.
class UserHomeDashboard {
  /// Display name of the current user.
  final String userName;

  /// Time-based greeting (e.g., "Good morning").
  final String greeting;

  /// Weather information for today (optional).
  final UserHomeWeather? weather;

  /// List of quick link actions available to the user.
  final List<UserHomeQuickLink> quickLinks;

  /// Meal plan sections grouped by meal type.
  final List<UserHomeMealSection> mealPlan;

  /// Creates a new user home dashboard instance.
  const UserHomeDashboard({
    required this.userName,
    required this.greeting,
    required this.weather,
    required this.quickLinks,
    required this.mealPlan,
  });

  /// Creates a copy of this dashboard with optional field updates.
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

/// Weather information for the user home dashboard.
/// Contains temperature, condition, and other metrics.
class UserHomeWeather {
  /// Current temperature in degrees Celsius.
  final int currentTemp;

  /// Minimum temperature for the day in degrees Celsius.
  final int minTemp;

  /// Maximum temperature for the day in degrees Celsius.
  final int maxTemp;

  /// Weather condition (e.g., sunny, rainy, cloudy).
  final String condition;

  /// Human-readable weather summary.
  final String summary;

  /// Humidity percentage.
  final int humidity;

  /// Wind speed in km/h.
  final int windSpeed;

  /// UV index level (e.g., "Low", "Moderate", "High").
  final String uvIndex;

  /// Creates a new user home weather instance.
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

/// Target destinations for quick links.
enum UserHomeQuickLinkTarget {
  /// Navigate to explore recipes page.
  explore,

  /// Navigate to add recipe page.
  addRecipe,

  /// Navigate to meal plan page.
  mealPlan,

  /// Navigate to try AI page.
  tryAi,

  /// Navigate to grocery list page.
  groceryList,

  /// Navigate to statistics page.
  statistics,
}

/// Quick link item for the home dashboard.
/// Contains title, icon, and navigation target.
class UserHomeQuickLink {
  /// Display title of the quick link.
  final String title;

  /// Icon to display for the quick link.
  final IconData icon;

  /// Navigation target for the quick link.
  final UserHomeQuickLinkTarget target;

  /// Creates a new user home quick link instance.
  const UserHomeQuickLink({
    required this.title,
    required this.icon,
    required this.target,
  });
}

/// Meal section grouped by meal type.
/// Contains meals for a specific category (e.g., Breakfast, Lunch).
class UserHomeMealSection {
  /// Type of meal (e.g., Breakfast, Lunch, Dinner).
  final String mealType;

  /// Label showing the count of meals in this section.
  final String countLabel;

  /// Accent color for the section.
  final Color accentColor;

  /// Icon representing the meal type.
  final IconData icon;

  /// List of meals in this section.
  final List<UserHomeMeal> meals;

  /// Creates a new user home meal section instance.
  const UserHomeMealSection({
    required this.mealType,
    required this.countLabel,
    required this.accentColor,
    required this.icon,
    required this.meals,
  });
}

/// Individual meal item in a meal section.
/// Contains title, subtitle, duration, and image path.
class UserHomeMeal {
  /// Display title of the meal.
  final String title;

  /// Subtitle or description of the meal.
  final String subtitle;

  /// Duration label (e.g., "30 mins").
  final String duration;

  /// Path to the meal's image asset.
  final String imagePath;

  /// Creates a new user home meal instance.
  const UserHomeMeal({
    required this.title,
    required this.subtitle,
    required this.duration,
    required this.imagePath,
  });
}