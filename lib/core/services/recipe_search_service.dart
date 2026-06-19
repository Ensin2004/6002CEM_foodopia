import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/env_config.dart';

class RecipeSearchMetadata {
  final List<String> tags;

  const RecipeSearchMetadata({required this.tags});
}

/// Generates searchable recipe tags.
class RecipeSearchService {
  final http.Client client;

  const RecipeSearchService({required this.client});

  Future<RecipeSearchMetadata> buildRecipeMetadata(String recipeText) async {
    final tags = await _generateTags(recipeText);
    return RecipeSearchMetadata(tags: tags);
  }

  Future<List<String>> _generateTags(String recipeText) async {
    final apiKey = EnvConfig.openAiApiKey.trim();
    if (apiKey.isEmpty) return const [];

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
        .timeout(const Duration(seconds: 45));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Recipe tag generation failed: ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final output = body['output'] as List<dynamic>? ?? const [];
    String jsonText = '';
    for (final item in output.whereType<Map<String, dynamic>>()) {
      for (final content in (item['content'] as List<dynamic>? ?? const [])) {
        if (content is Map<String, dynamic> &&
            content['type'] == 'output_text') {
          jsonText = content['text']?.toString() ?? '';
        }
      }
    }
    final payload = jsonDecode(jsonText) as Map<String, dynamic>;
    return (payload['tags'] as List<dynamic>? ?? const [])
        .map((tag) => tag.toString().trim().toLowerCase())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }
}
