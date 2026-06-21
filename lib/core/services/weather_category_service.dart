/// Represents a weather category with an ID, label, and description.
class WeatherCategory {
  /// Unique identifier for the weather category.
  final String id;

  /// Display label for the weather category.
  final String label;

  /// Description of the weather category.
  final String description;

  /// Creates a new weather category instance.
  const WeatherCategory({
    required this.id,
    required this.label,
    required this.description,
  });
}

/// Service for matching weather conditions to categories.
/// Provides predefined weather categories and matching logic.
class WeatherCategoryService {
  /// List of all available weather categories.
  static const List<WeatherCategory> categories = [
    WeatherCategory(
      id: 'sunny',
      label: 'Sunny',
      description: 'Fresh, cooling meals and lighter bowls.',
    ),
    WeatherCategory(
      id: 'rainy',
      label: 'Rainy',
      description: 'Warm, cozy meals with soup or baked dishes.',
    ),
    WeatherCategory(
      id: 'windy',
      label: 'Windy',
      description: 'Comfort meals that still feel balanced.',
    ),
    WeatherCategory(
      id: 'cloudy',
      label: 'Cloudy',
      description: 'Simple everyday meals with mild flavors.',
    ),
    WeatherCategory(
      id: 'hot',
      label: 'Hot',
      description: 'Hydrating meals, salads and quick cooking.',
    ),
    WeatherCategory(
      id: 'cool',
      label: 'Cool',
      description: 'Hearty meals with grains, roasts and stews.',
    ),
  ];

  /// Matches a weather condition and temperature to a category.
  static WeatherCategory matchCondition(String condition, int temperature) {
    // Normalize the condition string.
    final normalized = condition.toLowerCase();

    // Check for rainy/thunderstorm conditions.
    if (normalized.contains('rain') || normalized.contains('thunder')) {
      return categories.firstWhere((item) => item.id == 'rainy');
    }

    // Check for windy conditions.
    if (normalized.contains('wind')) {
      return categories.firstWhere((item) => item.id == 'windy');
    }

    // Check for hot temperatures.
    if (temperature >= 32) {
      return categories.firstWhere((item) => item.id == 'hot');
    }

    // Check for cool temperatures.
    if (temperature <= 22) {
      return categories.firstWhere((item) => item.id == 'cool');
    }

    // Check for cloudy/foggy conditions.
    if (normalized.contains('cloud') || normalized.contains('fog')) {
      return categories.firstWhere((item) => item.id == 'cloudy');
    }

    // Default to sunny.
    return categories.firstWhere((item) => item.id == 'sunny');
  }

  /// Retrieves a weather category by ID.
  static WeatherCategory byId(String id) {
    return categories.firstWhere(
          (item) => item.id == id,
      orElse: () => categories.first,
    );
  }
}