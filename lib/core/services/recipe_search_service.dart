import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env_config.dart';

/// Holds the generated search metadata for a recipe.
///
/// Contains a list of tags that describe various aspects of the recipe
/// such as cuisine type, meal category, dietary attributes, cooking methods,
/// and key ingredients.
class RecipeSearchMetadata {
  final List<String> tags;

  const RecipeSearchMetadata({required this.tags});
}

/// Generates searchable recipe tags from recipe text using OpenAI's API.
///
/// This service processes recipe descriptions and produces a curated list
/// of search tags that enable efficient recipe discovery and filtering.
class RecipeSearchService {
  final http.Client client;

  const RecipeSearchService({required this.client});

  /// Builds a [RecipeSearchMetadata] object containing search tags.
  ///
  /// Takes a [recipeText] string containing the recipe description or content.
  /// Returns a [Future] that completes with the generated metadata.
  Future<RecipeSearchMetadata> buildRecipeMetadata(String recipeText) async {
    final tags = await _generateTags(recipeText);
    return RecipeSearchMetadata(tags: tags);
  }

  /// Generates a list of search tags from the provided recipe text.
  ///
  /// This method calls the OpenAI API with a structured JSON schema request
  /// to ensure consistent, valid tag generation. Returns an empty list if
  /// the API key is not configured or if the API call fails.
  Future<List<String>> _generateTags(String recipeText) async {
    // Retrieve and validate the OpenAI API key from environment configuration.
    final apiKey = EnvConfig.openAiApiKey.trim();
    if (apiKey.isEmpty) return const [];

    // Send a POST request to OpenAI's responses endpoint with the recipe text.
    // The request includes a system prompt that instructs the model on what
    // types of tags to generate (cuisine, meal type, dietary traits, etc.).
    final response = await client
        .post(
      Uri.parse('https://api.openai.com/v1/responses'),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': EnvConfig.openAiRecipeModel,
        'max_output_tokens': 300,
        'input': [
          {
            'role': 'system',
            'content':
            'Generate concise recipe search tags. Include cuisine, meal type, '
                'dietary traits, cooking method, main ingredients and useful '
                'descriptors. Return only the requested JSON.',
          },
          {'role': 'user', 'content': recipeText},
        ],
        'text': {
          'format': {
            'type': 'json_schema',
            'name': 'recipe_search_tags',
            'strict': true,
            'schema': {
              'type': 'object',
              'properties': {
                'tags': {
                  'type': 'array',
                  'items': {'type': 'string'},
                  'minItems': 5,
                  'maxItems': 12,
                },
              },
              'required': ['tags'],
              'additionalProperties': false,
            },
          },
        },
      }),
    )
        .timeout(const Duration(seconds: 45)); // Prevent indefinite waiting.

    // Check for HTTP error status codes and throw an exception if the request failed.
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Recipe tag generation failed: ${response.body}');
    }

    // Parse the JSON response body into a Map for further processing.
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    // Extract the 'output' array from the response, defaulting to an empty list.
    final output = body['output'] as List<dynamic>? ?? const [];

    // Search through the response output to find the generated text content.
    // The API response structure nests content within multiple levels.
    String jsonText = '';
    for (final item in output.whereType<Map<String, dynamic>>()) {
      for (final content in (item['content'] as List<dynamic>? ?? const [])) {
        if (content is Map<String, dynamic> &&
            content['type'] == 'output_text') {
          jsonText = content['text']?.toString() ?? '';
        }
      }
    }

    // Decode the extracted JSON string into a Map and retrieve the tags array.
    final payload = jsonDecode(jsonText) as Map<String, dynamic>;

    // Process the tags list: cast to strings, trim whitespace, convert to lowercase,
    // filter out empty strings, deduplicate by converting to a Set, and convert back to a List.
    return (payload['tags'] as List<dynamic>? ?? const [])
        .map((tag) => tag.toString().trim().toLowerCase())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }
}