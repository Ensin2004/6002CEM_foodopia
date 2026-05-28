import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env_config.dart';
import '../../features/recipe/domain/entities/add_recipe_ingredient_data.dart';

class OpenAiIngredientDataService {
  final http.Client client;

  const OpenAiIngredientDataService({required this.client});

  Future<List<AddRecipeIngredientData>> analyzeIngredients({
    required List<AddRecipeIngredientDataInput> ingredients,
    required List<AddRecipeIngredientCategory> categories,
  }) async {
    final apiKey = EnvConfig.openAiApiKey.trim();
    if (apiKey.isEmpty) {
      throw StateError(
        'OPENAI_API_KEY is missing. Add it to your dart defines before saving ingredient analysis.',
      );
    }

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
              'max_output_tokens': 2500,
              'input': [
                {
                  'role': 'system',
                  'content':
                  'You are Foodopia ingredient AI. Return only valid JSON that matches the requested schema.',
                },
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
          .timeout(const Duration(seconds: 60));
    } on TimeoutException {
      throw TimeoutException(
        'OpenAI took too long to analyze ingredients. Please try again, or switch OPENAI_RECIPE_MODEL to a faster mini model.',
        const Duration(seconds: 60),
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('OpenAI ingredient analyze request failed: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content = _extractOutputText(decoded);
    final payload = jsonDecode(content) as Map<String, dynamic>;
    final items = payload['ingredients'] as List<dynamic>? ?? const [];

    return items
        .whereType<Map<String, dynamic>>()
        .map(_analysisFromJson)
        .toList();
  }

  String _buildPrompt(
    List<AddRecipeIngredientDataInput> ingredients,
    List<AddRecipeIngredientCategory> categories,
  ) {
    final categoryPayload = categories
        .map((item) => {'id': item.id, 'name': item.name})
        .toList(growable: false);
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
- Return nutrients for each ingredient as calories, carbohydrates, fat and protein.
- Nutrients are for the provided amount and unit.
- If usdaNutrients is provided, keep only calories, carbohydrates, fat and protein from USDA and use those values.
- If usdaNutrients is missing or incomplete, estimate calories, carbohydrates, fat and protein from the ingredient, amount and unit.
- Use kcal for calories and grams for carbohydrates, fat and protein.
''';
  }

  String _extractOutputText(Map<String, dynamic> decoded) {
    final output = decoded['output'] as List<dynamic>? ?? const [];
    for (final item in output.whereType<Map<String, dynamic>>()) {
      final content = item['content'] as List<dynamic>? ?? const [];
      for (final part in content.whereType<Map<String, dynamic>>()) {
        final text = part['text'];
        if (text is String && text.trim().isNotEmpty) return text;
      }
    }
    final direct = decoded['output_text'];
    if (direct is String && direct.trim().isNotEmpty) return direct;
    throw StateError('OpenAI response did not include ingredient JSON.');
  }

  AddRecipeIngredientData _analysisFromJson(Map<String, dynamic> json) {
    final nutrients = json['nutrients'] as Map<String, dynamic>? ?? const {};
    return AddRecipeIngredientData(
      index: (json['index'] as num?)?.toInt() ?? -1,
      ingredientCategoryId:
          json['ingredientCategoryId']?.toString().trim() ?? '',
      nutrients: {
        'calories': _numberValue(nutrients['calories']),
        'carbohydrates': _numberValue(nutrients['carbohydrates']),
        'fat': _numberValue(nutrients['fat']),
        'protein': _numberValue(nutrients['protein']),
      },
    );
  }

  double _numberValue(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is Map) return _numberValue(value['value']);
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

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
            'required': ['calories', 'carbohydrates', 'fat', 'protein'],
            'properties': {
              'calories': {'type': 'number'},
              'carbohydrates': {'type': 'number'},
              'fat': {'type': 'number'},
              'protein': {'type': 'number'},
            },
          },
        },
      },
    },
  },
};
