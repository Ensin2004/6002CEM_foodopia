class WeatherCategory {
  final String id;
  final String label;
  final String description;

  const WeatherCategory({
    required this.id,
    required this.label,
    required this.description,
  });
}

class WeatherCategoryService {
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

  static WeatherCategory matchCondition(String condition, int temperature) {
    final normalized = condition.toLowerCase();
    if (normalized.contains('rain') || normalized.contains('thunder')) {
      return categories.firstWhere((item) => item.id == 'rainy');
    }
    if (normalized.contains('wind')) {
      return categories.firstWhere((item) => item.id == 'windy');
    }
    if (temperature >= 32) {
      return categories.firstWhere((item) => item.id == 'hot');
    }
    if (temperature <= 22) {
      return categories.firstWhere((item) => item.id == 'cool');
    }
    if (normalized.contains('cloud') || normalized.contains('fog')) {
      return categories.firstWhere((item) => item.id == 'cloudy');
    }
    return categories.firstWhere((item) => item.id == 'sunny');
  }

  static WeatherCategory byId(String id) {
    return categories.firstWhere(
      (item) => item.id == id,
      orElse: () => categories.first,
    );
  }
}
