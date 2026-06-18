import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env_config.dart';
import '../../features/recipe/domain/entities/add_recipe_ingredient_data.dart';

/// Sends ingredient to OpenAI and returns category and nutrients info for each ingredient.
/// Uses OpenAI's Responses API to analyze ingredients with structured output.
class OpenAiIngredientDataService {
  /// HTTP client for making API requests.
  final http.Client client;

  /// Creates a new OpenAI ingredient data service instance.
  const OpenAiIngredientDataService({required this.client});

  // =========================================================================
  // INGREDIENT ANALYSIS
  // =========================================================================

  /// Request category and nutrients info and converts the JSON response into app ingredient data entities.
  Future<List<AddRecipeIngredientData>> analyzeIngredients({
    required List<AddRecipeIngredientDataInput> ingredients,
    required List<AddRecipeIngredientCategory> categories,
  }) async {
    // Get the API key from environment configuration.
    final apiKey = EnvConfig.openAiApiKey.trim();

    // Validate the API key.
    if (apiKey.isEmpty) {
      throw StateError(
        'OPENAI_API_KEY is missing. Add it to your dart defines before saving ingredient analysis.',
      );
    }

    // Make the API request.
    late final http.Response response;
    try {
      response = await client
          .post(
            Uri.parse('https://api.openai.com/v1/responses'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': EnvConfig.openAiIngredientModel,
              'max_output_tokens': 8000,
              'input': [
                // System instruction.
                {
                  'role': 'system',
                  'content':
                      'You are Foodopia ingredient AI. Return only valid JSON that matches the requested schema.',
                },
                // User prompt with ingredient data.
                {
                  'role': 'user',
                  'content': _buildPrompt(ingredients, categories),
                },
              ],
              'text': {
                'format': {
                  'type': 'json_schema',
                  'name': 'foodopia_ingredient_analysis',
                  'schema': _ingredientAnalysisSchema,
                  'strict': true,
                },
              },
            }),
          )
          .timeout(const Duration(seconds: 90));
    } on TimeoutException {
      throw TimeoutException(
        'OpenAI took too long to analyze ingredients. Please try again, or switch OPENAI_RECIPE_MODEL to a faster mini model.',
        const Duration(seconds: 90),
      );
    }

    // Handle error response.
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'OpenAI ingredient analyze request failed: ${response.body}',
      );
    }

    // Parse the response.
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    // Extract the JSON content from the response.
    final content = _extractOutputText(decoded);
    final payload = jsonDecode(content) as Map<String, dynamic>;

    // Extract ingredients from the payload.
    final items = payload['ingredients'] as List<dynamic>? ?? const [];

    // Convert each item to AddRecipeIngredientData.
    return items
        .whereType<Map<String, dynamic>>()
        .map(_analysisFromJson)
        .toList();
  }

  // =========================================================================
  // PROMPT BUILDING
  // =========================================================================

  /// Builds the prompt with required info and rules.
  String _buildPrompt(
    List<AddRecipeIngredientDataInput> ingredients,
    List<AddRecipeIngredientCategory> categories,
  ) {
    // Build category payload.
    final categoryPayload = categories
        .map((item) => {'id': item.id, 'name': item.name})
        .toList(growable: false);

    // Build ingredient payload.
    final ingredientPayload = ingredients
        .map((item) => {
              'index': item.index,
              'name': item.name,
              'amount': item.amount,
              'unit': item.unit,
              'usdaNutrients': item.usdaNutrients,
            })
        .toList(growable: false);

    return '''
Analyze all ingredients.

Categories:
${jsonEncode(categoryPayload)}

Ingredients:
${jsonEncode(ingredientPayload)}

Rules:
- For each ingredient, choose exactly one category id from the provided categories.
- Do not create new categories.
- If an ingredient does not clearly match any category, use the provided category named "Others".
- Return ingredientCategoryId as the selected category id.
- Return nutrients for each ingredient as calories, protein, carbohydrates, fat, fiber, water, vitaminA, vitaminC, vitaminD, vitaminE, vitaminK, vitaminB1, vitaminB2, vitaminB3, vitaminB6, vitaminB9, vitaminB12, calcium, iron, magnesium, phosphorus, potassium, sodium and zinc.
- Nutrients are for the provided amount and unit.
- If usdaNutrients is provided, keep any provided nutrient values and estimate missing or zero values.
- Use kcal for calories; grams for protein, carbohydrates, fat, fiber and water; milligrams for vitaminC, vitaminE, vitaminB1, vitaminB2, vitaminB3, vitaminB6, calcium, iron, magnesium, phosphorus, potassium, sodium and zinc; micrograms for vitaminA, vitaminD, vitaminK, vitaminB9 and vitaminB12.
''';
  }

  // =========================================================================
  // RESPONSE PARSING
  // =========================================================================

  /// Reads text content from the Responses API output format.
  String _extractOutputText(Map<String, dynamic> decoded) {
    // Try to get output from the 'output' field.
    final output = decoded['output'] as List<dynamic>? ?? const [];

    for (final item in output.whereType<Map<String, dynamic>>()) {
      final content = item['content'] as List<dynamic>? ?? const [];

      for (final part in content.whereType<Map<String, dynamic>>()) {
        final text = part['text'];
        if (text is String && text.trim().isNotEmpty) return text;
      }
    }

    // Try to get output from the 'output_text' field.
    final direct = decoded['output_text'];
    if (direct is String && direct.trim().isNotEmpty) return direct;

    // Throw error if no output found.
    throw StateError('OpenAI response did not include ingredient JSON.');
  }

  /// Converts the results from JSON into desired format.
  AddRecipeIngredientData _analysisFromJson(Map<String, dynamic> json) {
    // Extract nutrients.
    final nutrients = json['nutrients'] as Map<String, dynamic>? ?? const {};

    return AddRecipeIngredientData(
      index: (json['index'] as num?)?.toInt() ?? -1,
      ingredientCategoryId:
      json['ingredientCategoryId']?.toString().trim() ?? '',
      nutrients: {
        'calories': _numberValue(nutrients['calories']),
        'protein': _numberValue(nutrients['protein']),
        'carbohydrates': _numberValue(nutrients['carbohydrates']),
        'fat': _numberValue(nutrients['fat']),
        'fiber': _numberValue(nutrients['fiber']),
        'water': _numberValue(nutrients['water']),
        'vitaminA': _numberValue(nutrients['vitaminA']),
        'vitaminC': _numberValue(nutrients['vitaminC']),
        'vitaminD': _numberValue(nutrients['vitaminD']),
        'vitaminE': _numberValue(nutrients['vitaminE']),
        'vitaminK': _numberValue(nutrients['vitaminK']),
        'vitaminB1': _numberValue(nutrients['vitaminB1']),
        'vitaminB2': _numberValue(nutrients['vitaminB2']),
        'vitaminB3': _numberValue(nutrients['vitaminB3']),
        'vitaminB6': _numberValue(nutrients['vitaminB6']),
        'vitaminB9': _numberValue(nutrients['vitaminB9']),
        'vitaminB12': _numberValue(nutrients['vitaminB12']),
        'calcium': _numberValue(nutrients['calcium']),
        'iron': _numberValue(nutrients['iron']),
        'magnesium': _numberValue(nutrients['magnesium']),
        'phosphorus': _numberValue(nutrients['phosphorus']),
        'potassium': _numberValue(nutrients['potassium']),
        'sodium': _numberValue(nutrients['sodium']),
        'zinc': _numberValue(nutrients['zinc']),
      },
    );
  }

  // =========================================================================
  // PRIVATE HELPERS
  // =========================================================================

  /// Converts numeric, nested numeric, and string numeric values into doubles.
  double _numberValue(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is Map) return _numberValue(value['value']);
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

// =========================================================================
// JSON SCHEMA
// =========================================================================

/// JSON schema for the AI, to ensure the results are provided in correct format.
const Map<String, dynamic> _ingredientAnalysisSchema = {
  'type': 'object',
  'additionalProperties': false,
  'required': ['ingredients'],
  'properties': {
    'ingredients': {
      'type': 'array',
      'items': {
        'type': 'object',
        'additionalProperties': false,
        'required': ['index', 'ingredientCategoryId', 'nutrients'],
        'properties': {
          'index': {'type': 'integer'},
          'ingredientCategoryId': {'type': 'string'},
          'nutrients': {
            'type': 'object',
            'additionalProperties': false,
            'required': [
              'calories',
              'protein',
              'carbohydrates',
              'fat',
              'fiber',
              'water',
              'vitaminA',
              'vitaminC',
              'vitaminD',
              'vitaminE',
              'vitaminK',
              'vitaminB1',
              'vitaminB2',
              'vitaminB3',
              'vitaminB6',
              'vitaminB9',
              'vitaminB12',
              'calcium',
              'iron',
              'magnesium',
              'phosphorus',
              'potassium',
              'sodium',
              'zinc',
            ],
            'properties': {
              'calories': {'type': 'number'},
              'protein': {'type': 'number'},
              'carbohydrates': {'type': 'number'},
              'fat': {'type': 'number'},
              'fiber': {'type': 'number'},
              'water': {'type': 'number'},
              'vitaminA': {'type': 'number'},
              'vitaminC': {'type': 'number'},
              'vitaminD': {'type': 'number'},
              'vitaminE': {'type': 'number'},
              'vitaminK': {'type': 'number'},
              'vitaminB1': {'type': 'number'},
              'vitaminB2': {'type': 'number'},
              'vitaminB3': {'type': 'number'},
              'vitaminB6': {'type': 'number'},
              'vitaminB9': {'type': 'number'},
              'vitaminB12': {'type': 'number'},
              'calcium': {'type': 'number'},
              'iron': {'type': 'number'},
              'magnesium': {'type': 'number'},
              'phosphorus': {'type': 'number'},
              'potassium': {'type': 'number'},
              'sodium': {'type': 'number'},
              'zinc': {'type': 'number'},
            },
          },
        },
      },
    },
  },
};
