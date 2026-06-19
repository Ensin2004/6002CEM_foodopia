import '../../../../core/services/open_meteo_weather_service.dart';
import '../models/user_home_dashboard_model.dart';

/// Data source for user home weather information.
/// Fetches weather data from Open Meteo API.
class UserHomeWeatherDataSource {
  /// Fixed latitude coordinate for weather queries.
  static const double _latitude = 1.3521;

  /// Fixed longitude coordinate for weather queries.
  static const double _longitude = 103.8198;

  /// Service instance used to fetch weather data.
  final OpenMeteoWeatherService weatherService;

  /// Creates a new user home weather data source instance.
  UserHomeWeatherDataSource({required this.weatherService});

  /// Retrieves today's weather information.
  ///
  /// Uses fixed coordinates (Singapore) for consistent location data.
  /// Returns a model containing temperature, condition, and other metrics.
  Future<UserHomeWeatherModel> getTodayWeather() async {
    // Fetch weather data from the service.
    final weather = await weatherService.getTodayWeather(
      latitude: _latitude,
      longitude: _longitude,
    );

    // Map the service response to the domain model.
    return UserHomeWeatherModel(
      currentTemp: weather.currentTemp,
      minTemp: weather.minTemp,
      maxTemp: weather.maxTemp,
      condition: weather.condition,
      summary: weather.summary,
      humidity: weather.humidity,
      windSpeed: weather.windSpeed,
      uvIndex: weather.uvIndex,
    );
  }
}