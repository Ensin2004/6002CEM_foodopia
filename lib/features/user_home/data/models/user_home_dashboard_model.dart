import '../../domain/entities/user_home_dashboard.dart';

/// Model class for user home dashboard data.
/// Extends the domain entity with additional serialization capabilities.
class UserHomeDashboardModel extends UserHomeDashboard {
  /// Creates a new user home dashboard model instance.
  const UserHomeDashboardModel({
    required super.userName,
    required super.greeting,
    required super.weather,
    required super.quickLinks,
    required super.mealPlan,
  });
}

/// Model class for user home weather data.
/// Extends the domain weather entity.
class UserHomeWeatherModel extends UserHomeWeather {
  /// Creates a new user home weather model instance.
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