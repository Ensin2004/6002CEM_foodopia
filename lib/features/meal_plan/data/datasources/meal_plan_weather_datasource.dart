import '../../../../core/services/open_meteo_weather_service.dart';
import '../models/meal_plan_dashboard_model.dart';

/// Remote data source for fetching weather information.
/// Provides weather data for the meal plan dashboard.
class MealPlanWeatherDataSource {
  /// Fixed latitude coordinate for weather queries.
  static const double _latitude = 1.3521;

  /// Fixed longitude coordinate for weather queries.
  static const double _longitude = 103.8198;

  /// Service instance used to fetch weather data from Open Meteo API.
  final OpenMeteoWeatherService weatherService;

  /// Creates a new instance with the required weather service.
  const MealPlanWeatherDataSource({required this.weatherService});

  /// Retrieves weather information for a specific date.
  ///
  /// Uses fixed coordinates (Singapore) for consistent location data.
  /// Returns a model containing temperature, condition, and summary.
  Future<MealPlanWeatherModel> getWeatherForDate(DateTime date) async {
    // Fetch weather data from the service.
    final weather = await weatherService.getWeatherForDate(
      latitude: _latitude,
      longitude: _longitude,
      date: date,
    );

    // Map the service response to the domain model.
    return MealPlanWeatherModel(
      currentTemp: weather.currentTemp,
      condition: weather.condition,
      summary: weather.summary,
    );
  }
}