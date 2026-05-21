import 'dart:convert';

import 'package:http/http.dart' as http;

class OpenMeteoWeather {
  final int currentTemp;
  final int minTemp;
  final int maxTemp;
  final String condition;
  final String summary;
  final int humidity;
  final int windSpeed;
  final String uvIndex;

  const OpenMeteoWeather({
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

class OpenMeteoWeatherService {
  final http.Client client;

  OpenMeteoWeatherService({required this.client});

  Future<OpenMeteoWeather> getTodayWeather({
    required double latitude,
    required double longitude,
  }) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'current':
          'temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code',
      'daily': 'temperature_2m_max,temperature_2m_min,uv_index_max',
      'timezone': 'auto',
      'forecast_days': '1',
    });

    final response = await client.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Weather API failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final current = data['current'] as Map<String, dynamic>?;
    final daily = data['daily'] as Map<String, dynamic>?;
    if (current == null || daily == null) {
      throw Exception('Weather API returned incomplete data');
    }

    final weatherCode = _requiredInt(current['weather_code']);
    final condition = _conditionForCode(weatherCode);
    final uvIndex = _firstRequiredInt(daily['uv_index_max']);

    return OpenMeteoWeather(
      currentTemp: _requiredInt(current['temperature_2m']),
      minTemp: _firstRequiredInt(daily['temperature_2m_min']),
      maxTemp: _firstRequiredInt(daily['temperature_2m_max']),
      condition: condition,
      summary: _summaryForCondition(condition),
      humidity: _requiredInt(current['relative_humidity_2m']),
      windSpeed: _requiredInt(current['wind_speed_10m']),
      uvIndex: _uvLabel(uvIndex),
    );
  }

  int _firstRequiredInt(dynamic value) {
    if (value is List && value.isNotEmpty) {
      return _requiredInt(value.first);
    }
    throw Exception('Weather API returned missing daily values');
  }

  int _requiredInt(dynamic value) {
    if (value is num) return value.round();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed.round();
    }
    throw Exception('Weather API returned invalid numeric values');
  }

  String _conditionForCode(int code) {
    if (code == 0) return 'Clear';
    if (code >= 1 && code <= 3) return 'Partly Cloudy';
    if (code >= 45 && code <= 48) return 'Foggy';
    if (code >= 51 && code <= 67) return 'Rain';
    if (code >= 71 && code <= 77) return 'Snow';
    if (code >= 80 && code <= 86) return 'Rain Showers';
    if (code >= 95 && code <= 99) return 'Thunderstorm';
    return 'Unknown';
  }

  String _summaryForCondition(String condition) {
    switch (condition) {
      case 'Rain':
      case 'Rain Showers':
      case 'Thunderstorm':
        return 'Keep a cozy meal ready for a rainy day.';
      case 'Foggy':
        return 'A calm day ahead with lower visibility.';
      case 'Partly Cloudy':
        return 'Today is warm and partly cloudy.';
      case 'Clear':
        return 'A bright day for something fresh and cool.';
      default:
        return 'Weather data is available for today.';
    }
  }

  String _uvLabel(int value) {
    if (value <= 2) return 'Low';
    if (value <= 5) return 'Moderate';
    if (value <= 7) return 'High';
    return 'Very High';
  }
}
