import '../../../../core/services/open_meteo_weather_service.dart';
import '../models/user_home_dashboard_model.dart';

class UserHomeWeatherDataSource {
  static const double _latitude = 1.3521;
  static const double _longitude = 103.8198;

  final OpenMeteoWeatherService weatherService;

  UserHomeWeatherDataSource({required this.weatherService});

  Future<UserHomeWeatherModel> getTodayWeather() async {
    final weather = await weatherService.getTodayWeather(
      latitude: _latitude,
      longitude: _longitude,
    );

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
