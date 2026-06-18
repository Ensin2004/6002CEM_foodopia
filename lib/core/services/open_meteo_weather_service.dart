import 'dart:convert';

import 'package:http/http.dart' as http;

/// Weather data model from OpenMeteo API.
class OpenMeteoWeather {
  /// Current temperature in Celsius.
  final int currentTemp;

  /// Minimum temperature for the day in Celsius.
  final int minTemp;

  /// Maximum temperature for the day in Celsius.
  final int maxTemp;

  /// Weather condition (e.g., Clear, Rain, Cloudy).
  final String condition;

  /// Human-readable weather summary.
  final String summary;

  /// Humidity percentage.
  final int humidity;

  /// Wind speed in km/h.
  final int windSpeed;

  /// UV index label (e.g., Low, Moderate, High).
  final String uvIndex;

  /// Creates a new OpenMeteo weather instance.
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

/// Service for fetching weather data from OpenMeteo API.
/// Supports current, forecast, and historical weather queries.
class OpenMeteoWeatherService {
  /// HTTP client for making API requests.
  final http.Client client;

  /// Creates a new OpenMeteo weather service instance.
  OpenMeteoWeatherService({required this.client});

  // =========================================================================
  // TODAY'S WEATHER
  // =========================================================================

  /// Retrieves today's weather for a location.
  Future<OpenMeteoWeather> getTodayWeather({
    required double latitude,
    required double longitude,
  }) async {
    // Build the API URL.
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'current':
      'temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code',
      'daily': 'temperature_2m_max,temperature_2m_min,uv_index_max',
      'timezone': 'auto',
      'forecast_days': '1',
    });

    // Make the request.
    final response = await client.get(uri);

    // Handle error response.
    if (response.statusCode != 200) {
      throw Exception('Weather API failed: ${response.statusCode}');
    }

    // Parse the response.
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final current = data['current'] as Map<String, dynamic>?;
    final daily = data['daily'] as Map<String, dynamic>?;

    // Validate response data.
    if (current == null || daily == null) {
      throw Exception('Weather API returned incomplete data');
    }

    // Extract weather data.
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

  // =========================================================================
  // WEATHER FOR DATE
  // =========================================================================

  /// Retrieves weather for a specific date.
  Future<OpenMeteoWeather> getWeatherForDate({
    required double latitude,
    required double longitude,
    required DateTime date,
  }) async {
    // Get today's date without time.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get target date without time.
    final target = DateTime(date.year, date.month, date.day);

    // Calculate days ahead.
    final daysAhead = target.difference(today).inDays;

    // Check if date is before 1940 (historical data limit).
    if (target.isBefore(DateTime(1940))) {
      throw RangeError(
        'No temperature available because historical weather starts from 1940.',
      );
    }

    // Use historical weather for past dates.
    if (daysAhead < 0) {
      return getHistoricalWeatherForDate(
        latitude: latitude,
        longitude: longitude,
        date: target,
      );
    }

    // Check if date is too far ahead (forecast limit is 16 days).
    if (daysAhead > 16) {
      throw RangeError(
        'No temperature available because this date is too far ahead to forecast.',
      );
    }

    // Use today's weather for today.
    if (daysAhead == 0) {
      return getTodayWeather(latitude: latitude, longitude: longitude);
    }

    // Build the forecast URL for the specific date.
    final formattedDate = _dateParam(target);
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'daily':
      'weather_code,temperature_2m_max,temperature_2m_min,uv_index_max',
      'timezone': 'auto',
      'start_date': formattedDate,
      'end_date': formattedDate,
    });

    // Make the request.
    final response = await client.get(uri);

    // Handle error response.
    if (response.statusCode != 200) {
      throw Exception('Weather API failed: ${response.statusCode}');
    }

    // Parse the response.
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final daily = data['daily'] as Map<String, dynamic>?;

    // Validate response data.
    if (daily == null) {
      throw Exception('Weather API returned incomplete forecast data');
    }

    // Extract weather data.
    final minTemp = _firstRequiredInt(daily['temperature_2m_min']);
    final maxTemp = _firstRequiredInt(daily['temperature_2m_max']);
    final weatherCode = _firstRequiredInt(daily['weather_code']);
    final condition = _conditionForCode(weatherCode);
    final uvIndex = _firstRequiredInt(daily['uv_index_max']);

    return OpenMeteoWeather(
      currentTemp: ((minTemp + maxTemp) / 2).round(),
      minTemp: minTemp,
      maxTemp: maxTemp,
      condition: condition,
      summary:
      '${_summaryForCondition(condition)} Forecast range: $minTemp-$maxTemp C.',
      humidity: 0,
      windSpeed: 0,
      uvIndex: _uvLabel(uvIndex),
    );
  }

  // =========================================================================
  // HISTORICAL WEATHER
  // =========================================================================

  /// Retrieves historical weather for a past date.
  Future<OpenMeteoWeather> getHistoricalWeatherForDate({
    required double latitude,
    required double longitude,
    required DateTime date,
  }) async {
    // Format the date.
    final formattedDate = _dateParam(date);

    // Build the historical API URL.
    final uri = Uri.https('archive-api.open-meteo.com', '/v1/archive', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'daily':
      'weather_code,temperature_2m_max,temperature_2m_min,temperature_2m_mean',
      'timezone': 'auto',
      'start_date': formattedDate,
      'end_date': formattedDate,
    });

    // Make the request.
    final response = await client.get(uri);

    // Handle error response.
    if (response.statusCode != 200) {
      throw Exception('Historical weather API failed: ${response.statusCode}');
    }

    // Parse the response.
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final daily = data['daily'] as Map<String, dynamic>?;

    // Validate response data.
    if (daily == null) {
      throw Exception('Historical weather API returned incomplete data');
    }

    // Extract weather data.
    final minTemp = _firstRequiredInt(daily['temperature_2m_min']);
    final maxTemp = _firstRequiredInt(daily['temperature_2m_max']);
    final meanTemp = _firstRequiredInt(daily['temperature_2m_mean']);
    final weatherCode = _firstRequiredInt(daily['weather_code']);
    final condition = _conditionForCode(weatherCode);

    return OpenMeteoWeather(
      currentTemp: meanTemp,
      minTemp: minTemp,
      maxTemp: maxTemp,
      condition: condition,
      summary:
      'Historical weather for ${_dateParam(date)}. Range: $minTemp-$maxTemp C.',
      humidity: 0,
      windSpeed: 0,
      uvIndex: 'Historical',
    );
  }

  // =========================================================================
  // PRIVATE HELPERS
  // =========================================================================

  /// Extracts the first integer from a list or returns a single integer.
  int _firstRequiredInt(dynamic value) {
    if (value is List && value.isNotEmpty) {
      return _requiredInt(value.first);
    }
    throw Exception('Weather API returned missing daily values');
  }

  /// Converts a value to an integer.
  int _requiredInt(dynamic value) {
    if (value is num) return value.round();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed.round();
    }
    throw Exception('Weather API returned invalid numeric values');
  }

  /// Maps weather code to a human-readable condition.
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

  /// Returns a summary for a weather condition.
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

  /// Maps UV index value to a label.
  String _uvLabel(int value) {
    if (value <= 2) return 'Low';
    if (value <= 5) return 'Moderate';
    if (value <= 7) return 'High';
    return 'Very High';
  }

  /// Formats a date as YYYY-MM-DD.
  String _dateParam(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}