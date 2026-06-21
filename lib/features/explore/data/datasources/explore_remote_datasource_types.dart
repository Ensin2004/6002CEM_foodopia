part of 'explore_remote_datasource.dart';

// Internal data class holding creator profile information from the users collection.
class _CreatorProfile {
  final String name;
  final String profileImage;
  final int followerCount;

  const _CreatorProfile({
    required this.name,
    required this.profileImage,
    this.followerCount = 0,
  });
}

// Defines a nutrient's key, display label, unit, and recommended daily value.
class _NutrientDefinition {
  final String key;
  final String label;
  final String unit;
  final double dailyValue;

  const _NutrientDefinition({
    required this.key,
    required this.label,
    required this.unit,
    required this.dailyValue,
  });
}

// Predefined list of vitamin definitions with their standard daily values.
const List<_NutrientDefinition> _vitaminDefinitions = [
  _NutrientDefinition(
    key: 'vitaminA',
    label: 'Vitamin A',
    unit: 'mcg',
    dailyValue: 900,
  ),
  _NutrientDefinition(
    key: 'vitaminC',
    label: 'Vitamin C',
    unit: 'mg',
    dailyValue: 90,
  ),
  _NutrientDefinition(
    key: 'vitaminD',
    label: 'Vitamin D',
    unit: 'mcg',
    dailyValue: 20,
  ),
  _NutrientDefinition(
    key: 'vitaminE',
    label: 'Vitamin E',
    unit: 'mg',
    dailyValue: 15,
  ),
  _NutrientDefinition(
    key: 'vitaminK',
    label: 'Vitamin K',
    unit: 'mcg',
    dailyValue: 120,
  ),
  _NutrientDefinition(
    key: 'vitaminB1',
    label: 'Vitamin B1',
    unit: 'mg',
    dailyValue: 1.2,
  ),
  _NutrientDefinition(
    key: 'vitaminB2',
    label: 'Vitamin B2',
    unit: 'mg',
    dailyValue: 1.3,
  ),
  _NutrientDefinition(
    key: 'vitaminB3',
    label: 'Vitamin B3',
    unit: 'mg',
    dailyValue: 16,
  ),
  _NutrientDefinition(
    key: 'vitaminB6',
    label: 'Vitamin B6',
    unit: 'mg',
    dailyValue: 1.7,
  ),
  _NutrientDefinition(
    key: 'vitaminB9',
    label: 'Vitamin B9 (Folate)',
    unit: 'mcg',
    dailyValue: 400,
  ),
  _NutrientDefinition(
    key: 'vitaminB12',
    label: 'Vitamin B12',
    unit: 'mcg',
    dailyValue: 2.4,
  ),
];

// Predefined list of mineral definitions with their standard daily values.
const List<_NutrientDefinition> _mineralDefinitions = [
  _NutrientDefinition(
    key: 'calcium',
    label: 'Calcium',
    unit: 'mg',
    dailyValue: 1300,
  ),
  _NutrientDefinition(key: 'iron', label: 'Iron', unit: 'mg', dailyValue: 18),
  _NutrientDefinition(
    key: 'magnesium',
    label: 'Magnesium',
    unit: 'mg',
    dailyValue: 420,
  ),
  _NutrientDefinition(
    key: 'phosphorus',
    label: 'Phosphorus',
    unit: 'mg',
    dailyValue: 1250,
  ),
  _NutrientDefinition(
    key: 'potassium',
    label: 'Potassium',
    unit: 'mg',
    dailyValue: 4700,
  ),
  _NutrientDefinition(
    key: 'sodium',
    label: 'Sodium',
    unit: 'mg',
    dailyValue: 2300,
  ),
  _NutrientDefinition(key: 'zinc', label: 'Zinc', unit: 'mg', dailyValue: 11),
];