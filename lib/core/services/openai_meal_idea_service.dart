import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env_config.dart';
import '../../features/meal_plan/domain/entities/add_meal_ai_plan.dart';

/// Service for generating AI meal ideas using OpenAI's Responses API.
/// Creates recipes with ingredients, instructions, and generated images.
class OpenAiMealIdeaService {
  /// HTTP client for making API requests.
  final http.Client client;

  /// Creates a new OpenAI meal idea service instance.
  const OpenAiMealIdeaService({required this.client});

  // =========================================================================
  // GENERATE MEAL IDEAS
  // =========================================================================

  /// Generates AI meal ideas based on the given request.
  Future<List<AddMealAiRecipe>> generateMealIdeas(
      AddMealAiGenerationRequest request,
      ) async {
    // Get the API key from environment configuration.
    final apiKey = EnvConfig.openAiApiKey.trim();

    // Validate the API key.
    if (apiKey.isEmpty) {
      throw StateError(
        'OPENAI_API_KEY is missing. Add it to your dart defines before generating AI meals.',
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
          'model': EnvConfig.openAiRecipeModel,
          'max_output_tokens': 2500,
          'input': [
            // System instruction.
            {
              'role': 'system',
              'content':
              'You are Foodopia recipe AI. Return only valid JSON that matches the requested schema. Create practical home-cooking recipes with safe, concise instructions.',
            },
            // User prompt with request data.
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

    // Handle error response.
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('OpenAI recipe request failed: ${response.body}');
    }

    // Parse the response.
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    // Extract the JSON content.
    final content = _extractOutputText(decoded);
    final payload = jsonDecode(content) as Map<String, dynamic>;

    // Extract ideas from the payload.
    final ideas = payload['ideas'] as List<dynamic>? ?? const [];

    // Convert each idea to AddMealAiRecipe.
    final recipes = ideas
        .whereType<Map<String, dynamic>>()
        .map(_recipeFromJson)
        .toList();

    // Generate images for each recipe.
    final withImages = <AddMealAiRecipe>[];
    for (final recipe in recipes) {
      withImages.add(await _withGeneratedImage(recipe));
    }

    return withImages;
  }

  // =========================================================================
  // PROMPT BUILDING
  // =========================================================================

  /// Builds the prompt for the AI.
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

Each idea needs: name, recipe category, short description, prep time label, difficulty label, serving label, AI-estimated nutrition, 3 recommendation reasons, 4-8 ingredients with amount/unit, 5-8 cooking instructions, and a food photography image prompt.

Nutrition rules:
- Use AI estimates only. Do not use or reference USDA data.
- Recipe nutrition is for the full suggested serving label.
- Ingredient nutrition is for the provided ingredient amount and unit.
- Use kcal for calories and grams for carbohydrates, fat, and protein.
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
    throw StateError('OpenAI response did not include recipe JSON.');
  }

  /// Converts JSON to AddMealAiRecipe.
  AddMealAiRecipe _recipeFromJson(Map<String, dynamic> json) {
    // Get the title.
    final title = json['title']?.toString().trim() ?? 'AI Meal Idea';

    // Parse ingredients.
    final ingredients = (json['ingredients'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => AddMealAiIngredient(
        name: item['name']?.toString().trim() ?? '',
        amount: (item['amount'] as num?)?.toDouble() ?? 0,
        unit: item['unit']?.toString().trim() ?? '',
        calories: _numberValue(item['calories']),
        carbohydrates: _numberValue(item['carbohydrates']),
        fat: _numberValue(item['fat']),
        protein: _numberValue(item['protein']),
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
      carbohydrates: _numberValue(json['carbohydrates']),
      fat: _numberValue(json['fat']),
      protein: _numberValue(json['protein']),
      imagePrompt: json['imagePrompt']?.toString().trim() ?? title,
      categoryName: json['categoryName']?.toString().trim() ?? 'Main Dish',
    );
  }

  /// Converts a value to a double.
  double _numberValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  // =========================================================================
  // IMAGE GENERATION
  // =========================================================================

  /// Generates an image for a recipe using DALL-E.
  Future<AddMealAiRecipe> _withGeneratedImage(AddMealAiRecipe recipe) async {
    // Get the API key.
    final apiKey = EnvConfig.openAiApiKey.trim();

    try {
      // Make the image generation request.
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

      // Return the original recipe if image generation fails.
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return recipe;
      }

      // Parse the response.
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final data = decoded['data'] as List<dynamic>? ?? const [];
      final maps = data.whereType<Map<String, dynamic>>();
      final first = maps.isEmpty ? null : maps.first;
      final b64 = first?['b64_json']?.toString();

      // Return the original recipe if no image data.
      if (b64 == null || b64.isEmpty) return recipe;

      // Return the recipe with the generated image.
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
        carbohydrates: recipe.carbohydrates,
        fat: recipe.fat,
        protein: recipe.protein,
        imagePrompt: recipe.imagePrompt,
        categoryName: recipe.categoryName,
      );
    } catch (_) {
      // Return the original recipe on error.
      return recipe;
    }
  }
}

// =========================================================================
// JSON SCHEMA
// =========================================================================

/// JSON schema for the AI, to ensure the results are provided in correct format.
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
          'carbohydrates',
          'fat',
          'protein',
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
          'carbohydrates': {'type': 'number'},
          'fat': {'type': 'number'},
          'protein': {'type': 'number'},
          'reasons': {
            'type': 'array',
            'items': {'type': 'string'},
          },
          'ingredients': {
            'type': 'array',
            'items': {
              'type': 'object',
              'additionalProperties': false,
              'required': [
                'name',
                'amount',
                'unit',
                'calories',
                'carbohydrates',
                'fat',
                'protein',
              ],
              'properties': {
                'name': {'type': 'string'},
                'amount': {'type': 'number'},
                'unit': {'type': 'string'},
                'calories': {'type': 'number'},
                'carbohydrates': {'type': 'number'},
                'fat': {'type': 'number'},
                'protein': {'type': 'number'},
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