import '../../../../core/services/open_meteo_weather_service.dart';
import '../models/meal_plan_dashboard_model.dart';

class MealPlanWeatherDataSource {
  static const double _latitude = 1.3521;
  static const double _longitude = 103.8198;

  final OpenMeteoWeatherService weatherService;

  const MealPlanWeatherDataSource({required this.weatherService});

  Future<MealPlanWeatherModel> getTodayWeather() async {
    final weather = await weatherService.getTodayWeather(
      latitude: _latitude,
      longitude: _longitude,
    );

    return MealPlanWeatherModel(
      currentTemp: weather.currentTemp,
      condition: weather.condition,
      summary: weather.summary,
    );
  }
}
