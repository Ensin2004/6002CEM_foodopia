import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env_config.dart';
import '../../features/meal_plan/domain/entities/add_meal_ai_plan.dart';

class OpenAiMealIdeaService {
  final http.Client client;

  const OpenAiMealIdeaService({required this.client});

  Future<List<AddMealAiRecipe>> generateMealIdeas(
    AddMealAiGenerationRequest request,
  ) async {
    final apiKey = EnvConfig.openAiApiKey.trim();
    if (apiKey.isEmpty) {
      throw StateError(
        'OPENAI_API_KEY is missing. Add it to your dart defines before generating AI meals.',
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
              'model': EnvConfig.openAiRecipeModel,
              'max_output_tokens': 2500,
              'input': [
                {
                  'role': 'system',
                  'content':
                      'You are Foodopia recipe AI. Return only valid JSON that matches the requested schema. Create practical home-cooking recipes with safe, concise instructions.',
                },
                {'role': 'user', 'content': _buildPrompt(request)},
              ],
              'text': {
                'format': {
                  'type': 'json_schema',
                  'name': 'foodopia_ai_meal_ideas',
                  'schema': _recipeSchema,
                  'strict': true,
                },
              },
            }),
          )
          .timeout(const Duration(seconds: 90));
    } on TimeoutException {
      throw TimeoutException(
        'OpenAI took too long to generate recipes. Please try again, or switch OPENAI_RECIPE_MODEL to a faster mini model.',
        const Duration(seconds: 90),
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('OpenAI recipe request failed: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content = _extractOutputText(decoded);
    final payload = jsonDecode(content) as Map<String, dynamic>;
    final ideas = payload['ideas'] as List<dynamic>? ?? const [];
    final recipes = ideas
        .whereType<Map<String, dynamic>>()
        .map(_recipeFromJson)
        .toList();

    final withImages = <AddMealAiRecipe>[];
    for (final recipe in recipes) {
      withImages.add(await _withGeneratedImage(recipe));
    }
    return withImages;
  }

  String _buildPrompt(AddMealAiGenerationRequest request) {
    return '''
Generate exactly 3 AI recipe ideas for this meal plan.

Meal: ${request.mealType}
Date: ${request.planningDate.toIso8601String()}
Weather: ${request.weather.condition}, ${request.weather.temperature}C, ${request.weather.summary}
Diet: ${request.preferences.diet}
Allergies to avoid: ${request.preferences.allergies.join(', ')}
Disliked/avoid ingredients: ${request.ingredientsToAvoid.join(', ')}
Ingredients user has: ${request.ingredientsToInclude.join(', ')}
Dish types to include: ${request.dishIncludes.join(', ')}
Dish types to avoid: ${request.dishAvoids.join(', ')}
Cooking time: ${request.cookingTime}
Difficulty: ${request.difficulty}
Serving size: ${request.servingSize}

Each idea needs: name, recipe category, short description, prep time label, difficulty label, serving label, calories estimate, 3 recommendation reasons, 4-8 ingredients with amount/unit, 5-8 cooking instructions, and a food photography image prompt.
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
    throw StateError('OpenAI response did not include recipe JSON.');
  }

  AddMealAiRecipe _recipeFromJson(Map<String, dynamic> json) {
    final title = json['title']?.toString().trim() ?? 'AI Meal Idea';
    final ingredients = (json['ingredients'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => AddMealAiIngredient(
            name: item['name']?.toString().trim() ?? '',
            amount: (item['amount'] as num?)?.toDouble() ?? 0,
            unit: item['unit']?.toString().trim() ?? '',
          ),
        )
        .where((item) => item.name.isNotEmpty)
        .toList();

    return AddMealAiRecipe(
      id: 'ai_${DateTime.now().microsecondsSinceEpoch}_${title.hashCode}',
      title: title,
      durationLabel: json['durationLabel']?.toString().trim() ?? '30 mins',
      difficultyLabel: json['difficultyLabel']?.toString().trim() ?? 'Easy',
      servingLabel: json['servingLabel']?.toString().trim() ?? '2 servings',
      imagePath: 'assets/images/meal1.png',
      description: json['description']?.toString().trim() ?? '',
      reasons: (json['reasons'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      ingredients: ingredients,
      instructions: (json['instructions'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      calories: (json['calories'] as num?)?.round() ?? 0,
      imagePrompt: json['imagePrompt']?.toString().trim() ?? title,
      categoryName: json['categoryName']?.toString().trim() ?? 'Main Dish',
    );
  }

  Future<AddMealAiRecipe> _withGeneratedImage(AddMealAiRecipe recipe) async {
    final apiKey = EnvConfig.openAiApiKey.trim();
    try {
      final response = await client
          .post(
            Uri.parse('https://api.openai.com/v1/images/generations'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': EnvConfig.openAiImageModel,
              'prompt':
                  '${recipe.imagePrompt}. App recipe card food photography, natural light, appetizing plated dish, no text.',
              'size': '1024x1024',
              'quality': 'low',
              'n': 1,
            }),
          )
          .timeout(const Duration(seconds: 45));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return recipe;
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'] as List<dynamic>? ?? const [];
      final maps = data.whereType<Map<String, dynamic>>();
      final first = maps.isEmpty ? null : maps.first;
      final b64 = first?['b64_json']?.toString();
      if (b64 == null || b64.isEmpty) return recipe;

      return AddMealAiRecipe(
        id: recipe.id,
        title: recipe.title,
        durationLabel: recipe.durationLabel,
        difficultyLabel: recipe.difficultyLabel,
        servingLabel: recipe.servingLabel,
        imagePath: recipe.imagePath,
        imageBase64: b64,
        description: recipe.description,
        reasons: recipe.reasons,
        ingredients: recipe.ingredients,
        instructions: recipe.instructions,
        calories: recipe.calories,
        imagePrompt: recipe.imagePrompt,
        categoryName: recipe.categoryName,
      );
    } catch (_) {
      return recipe;
    }
  }
}

const Map<String, dynamic> _recipeSchema = {
  'type': 'object',
  'additionalProperties': false,
  'required': ['ideas'],
  'properties': {
    'ideas': {
      'type': 'array',
      'minItems': 3,
      'maxItems': 3,
      'items': {
        'type': 'object',
        'additionalProperties': false,
        'required': [
          'title',
          'description',
          'durationLabel',
          'difficultyLabel',
          'servingLabel',
          'calories',
          'reasons',
          'ingredients',
          'instructions',
          'imagePrompt',
          'categoryName',
        ],
        'properties': {
          'title': {'type': 'string'},
          'description': {'type': 'string'},
          'durationLabel': {'type': 'string'},
          'difficultyLabel': {'type': 'string'},
          'servingLabel': {'type': 'string'},
          'calories': {'type': 'integer'},
          'reasons': {
            'type': 'array',
            'items': {'type': 'string'},
          },
          'ingredients': {
            'type': 'array',
            'items': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['name', 'amount', 'unit'],
              'properties': {
                'name': {'type': 'string'},
                'amount': {'type': 'number'},
                'unit': {'type': 'string'},
              },
            },
          },
          'instructions': {
            'type': 'array',
            'items': {'type': 'string'},
          },
          'imagePrompt': {'type': 'string'},
          'categoryName': {'type': 'string'},
        },
      },
    },
  },
};
