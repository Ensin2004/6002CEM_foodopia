import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../features/recipe/domain/entities/add_recipe_basic_info.dart';
import '../../features/recipe/domain/entities/add_recipe_image_result.dart';
import '../../features/recipe/domain/entities/add_recipe_ingredient.dart';
import '../../features/recipe/domain/entities/add_recipe_instruction.dart';
import '../../features/recipe/domain/entities/add_recipe_review.dart';
import '../../features/recipe/domain/entities/add_recipe_video_result.dart';
import '../config/env_config.dart';

/// Result container for recipe content validation operations.
///
/// Contains a boolean validity flag and a human-readable message
/// explaining the validation outcome.
class RecipeContentValidationResult {
  final bool isValid;
  final String message;

  const RecipeContentValidationResult({
    required this.isValid,
    required this.message,
  });
}

/// Service that validates recipe content using OpenAI's API.
///
/// Provides validation for various recipe components including
/// basic information, ingredients, instructions, and complete reviews.
/// Also supports generating recipe drafts from image uploads.
class OpenAiRecipeContentValidationService {
  final http.Client client;

  const OpenAiRecipeContentValidationService({required this.client});

  /// Generates a recipe draft from an uploaded image file.
  ///
  /// Sends the image to OpenAI's API for analysis, determining if the image
  /// contains food-related content and extracting recipe information when possible.
  /// Returns a structured draft with recipe name, description, ingredients, and instructions.
  Future<AddRecipeImageDraft> generateRecipeFromImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes(); // Convert image file to bytes
    final mimeType = _mimeTypeForPath(imageFile.path); // Determine MIME type for image
    final response = await client
        .post(
      Uri.parse('https://api.openai.com/v1/responses'),
      headers: {
        'Authorization': 'Bearer ${_apiKey()}', // Authentication with OpenAI API key
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': EnvConfig.openAiRecipeModel,
        'max_output_tokens': 1600,
        'input': [
          {
            'role': 'system',
            'content':
            'You are Foodopia recipe image AI. Return only valid JSON matching the schema.',
          },
          {
            'role': 'user',
            'content': [
              {
                'type': 'input_text',
                'text':
                'Validate whether this image shows actual food, a prepared dish, cooking ingredients, or a cooking scene. If it is not food-related, set isFood false, give a short reason, and leave recipeName, description, ingredients, and instructions empty. If it is food-related, generate a sensible recipe name, a short appetizing recipe description, 1-12 visible or strongly implied ingredients with reasonable estimated amounts and common cooking units, and 3-8 concise cooking instructions for the dish. Do not invent impossible ingredients or steps.',
              },
              {
                'type': 'input_image',
                'image_url': 'data:$mimeType;base64,${base64Encode(bytes)}', // Base64 encoded image data
                'detail': 'low', // Use low detail to reduce token usage
              },
            ],
          },
        ],
        'text': {
          'format': {
            'type': 'json_schema',
            'name': 'foodopia_image_recipe',
            'schema': _imageRecipeSchema, // Enforce strict JSON schema validation
            'strict': true,
          },
        },
      }),
    )
        .timeout(const Duration(seconds: 90)); // 90-second timeout for image processing

    // Check for successful response status
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('OpenAI image ingredient request failed.');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final payload =
    jsonDecode(_extractOutputText(decoded)) as Map<String, dynamic>;

    // Build and return the recipe draft from validated payload
    return AddRecipeImageDraft(
      isFood: payload['isFood'] is bool ? payload['isFood'] as bool : false,
      reason: payload['reason']?.toString().trim() ?? '',
      recipeName: payload['recipeName']?.toString().trim() ?? '',
      description: payload['description']?.toString().trim() ?? '',
      ingredients: (payload['ingredients'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>() // Filter only valid map entries
          .map(
            (item) => AddRecipeVideoIngredient(
          name: item['name']?.toString().trim() ?? '',
          amount: (item['amount'] as num?)?.toDouble() ?? 0,
          unit: item['unit']?.toString().trim() ?? '',
        ),
      )
          .where(
            (item) =>
        item.name.isNotEmpty &&
            item.amount > 0 &&
            item.unit.trim().isNotEmpty, // Filter out invalid ingredients
      )
          .toList(),
      instructions: (payload['instructions'] as List<dynamic>? ?? const [])
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty) // Filter out empty instructions
          .toList(),
    );
  }

  /// Validates basic recipe information such as name and description.
  ///
  /// Checks for inappropriate content including profanity, slurs, hate speech,
  /// harassment, and other harmful content types.
  Future<RecipeContentValidationResult> validateBasicInfo(
      AddRecipeBasicInfo info,
      ) {
    return _validatePayload(
      title: 'Basic recipe information',
      systemInstruction:
      'You validate Foodopia recipe names and descriptions. Return only valid JSON. Reject profanity, slurs, hate, harassment, sexual content, self-harm content, nonsensical or weird recipe names, non-food recipe names, and inappropriate descriptions. Do not validate cooking logic, ingredient amounts, instruction logic, preparation time, difficulty, servings, or extreme values.',
      fallbackMessage: 'Recipe name or description looks inappropriate.',
      payload: {
        'recipeName': info.recipeName,
        'description': info.description,
        'otherNames': info.otherNames,
        'customCategories': info.customCategories,
        'preparationMinutes': info.preparationMinutes,
        'difficultyLevel': info.difficultyLevel,
        'servings': info.servings,
        'customAllergens': info.customAllergens,
      },
    );
  }

  /// Validates ingredient units for proper measurement specifications.
  ///
  /// Checks for missing units, profane units, nonsensical measurements,
  /// or units incompatible with the ingredient and amount.
  Future<RecipeContentValidationResult> validateIngredients(
      List<AddRecipeIngredient> ingredients,
      ) {
    return _validatePayload(
      title: 'Recipe ingredients',
      systemInstruction:
      'You validate only ingredient unit usage for Foodopia. Return only valid JSON. Reject if a unit is missing, profane, nonsensical as a measurement unit, or clearly incompatible with the ingredient and amount. Do not reject ingredient count, ingredient amount being too high or too low, ingredient name, cooking logic, nutrition logic, or extreme values.',
      fallbackMessage: 'One or more ingredient units look incorrect.',
      payload: {
        'ingredients': ingredients
            .map(
              (item) => {
            'name': item.name,
            'amount': item.amount,
            'unit': item.customUnit.isNotEmpty
                ? item.customUnit
                : item.unitId, // Prefer custom unit over standard unit ID
          },
        )
            .toList(),
      },
    );
  }

  /// Validates recipe instructions for inappropriate language only.
  ///
  /// Checks for profanity, slurs, hate speech, harassment, sexual content,
  /// self-harm content, and explicit unsafe abuse in instruction text.
  Future<RecipeContentValidationResult> validateInstructions({
    required bool useSections,
    required List<AddRecipeInstruction> instructions,
  }) {
    return _validateInstructionLanguagePayload(
      payload: {
        'useSections': useSections,
        'instructions': instructions
            .map(
              (item) => {
            'sectionTitle': item.sectionTitle,
            'stepIndex': item.stepIndex,
            'description': item.description,
          },
        )
            .toList(),
      },
    );
  }

  /// Performs comprehensive review validation on a complete recipe.
  ///
  /// Checks for cooking-logic concerns, impossible steps, unsafe cooking logic,
  /// and extreme values. This validation is advisory only and flags recipes
  /// for review without blocking saving.
  Future<RecipeContentValidationResult> validateReview(AddRecipeReview review) {
    return _validatePayload(
      title: 'Complete recipe',
      systemInstruction:
      'You review complete Foodopia recipes for cooking-logic or extreme-value concerns. Return only valid JSON. Mark invalid when the recipe has impossible cooking steps, unsafe cooking logic, clearly impossible ingredient/prep/serving values, or extreme values. This result is advisory only and should flag the recipe, not block saving.',
      fallbackMessage:
      'Recipe may need review for cooking logic or extreme values.',
      payload: {
        'recipeName': review.recipeName,
        'description': review.description,
        'otherNames': review.otherNames,
        'categories': review.categories,
        'preparationMinutes': review.preparationMinutes,
        'difficultyLevel': review.difficultyLevel,
        'servings': review.servings,
        'allergens': review.allergens,
        'ingredients': review.ingredients
            .map(
              (item) => {
            'name': item.name,
            'amount': item.amount,
            'unit': item.unit,
          },
        )
            .toList(),
      },
    );
  }

  /// Internal method for validating instruction language specifically.
  ///
  /// Separated from the general validation to focus specifically on
  /// language concerns in instruction text.
  Future<RecipeContentValidationResult> _validateInstructionLanguagePayload({
    required Map<String, dynamic> payload,
  }) async {
    final response = await client
        .post(
      Uri.parse('https://api.openai.com/v1/responses'),
      headers: {
        'Authorization': 'Bearer ${_apiKey()}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': EnvConfig.openAiRecipeModel,
        'max_output_tokens': 500,
        'input': [
          {
            'role': 'system',
            'content':
            'You validate recipe instruction text for Foodopia. Return only valid JSON. Reject only bad/inappropriate wording: profanity, slurs, hate, harassment, sexual content, self-harm content, or explicit unsafe abuse. Do not reject for cooking logic, recipe quality, missing detail, weird but harmless phrasing, or extreme values.',
          },
          {
            'role': 'user',
            'content':
            'Validate only the wording of these recipe instructions. If invalid, provide one short user friendly reason. Payload: ${jsonEncode(payload)}',
          },
        ],
        'text': {
          'format': {
            'type': 'json_schema',
            'name': 'foodopia_instruction_language_validation',
            'schema': _validationSchema,
            'strict': true,
          },
        },
      }),
    )
        .timeout(const Duration(seconds: 60)); // 60-second timeout for instruction validation

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('OpenAI instruction validation request failed.');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final result =
    jsonDecode(_extractOutputText(decoded)) as Map<String, dynamic>;
    final isValid = result['isValid'] is bool
        ? result['isValid'] as bool
        : false;
    final reason = result['reason']?.toString().trim() ?? '';
    return RecipeContentValidationResult(
      isValid: isValid,
      message: isValid
          ? ''
          : reason.isEmpty
          ? 'Instructions contain inappropriate language.'
          : reason,
    );
  }

  /// Core validation method that sends payload to OpenAI for validation.
  ///
  /// Handles the HTTP request/response cycle, error handling, and result parsing.
  /// Used as the foundation for all validation operations.
  Future<RecipeContentValidationResult> _validatePayload({
    required String title,
    required Map<String, dynamic> payload,
    String systemInstruction =
    'You validate recipe content for Foodopia. Return only valid JSON. Reject profanity, sexual content, hate, harassment, self-harm, unsafe instructions, nonsensical names, non-food content, illogical cooking content, impossible steps, and extreme values. Be strict but allow normal creative recipe names.',
    String fallbackMessage =
    'Recipe content looks inappropriate or unrealistic.',
  }) async {
    final response = await client
        .post(
      Uri.parse('https://api.openai.com/v1/responses'),
      headers: {
        'Authorization': 'Bearer ${_apiKey()}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': EnvConfig.openAiRecipeModel,
        'max_output_tokens': 700,
        'input': [
          {'role': 'system', 'content': systemInstruction},
          {
            'role': 'user',
            'content':
            'Validate this $title. If invalid, provide one short user friendly reason. Payload: ${jsonEncode(payload)}',
          },
        ],
        'text': {
          'format': {
            'type': 'json_schema',
            'name': 'foodopia_recipe_validation',
            'schema': _validationSchema,
            'strict': true,
          },
        },
      }),
    )
        .timeout(const Duration(seconds: 60)); // 60-second timeout for validation requests

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('OpenAI recipe validation request failed.');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final payloadText = _extractOutputText(decoded);
    final result = jsonDecode(payloadText) as Map<String, dynamic>;
    final isValid = result['isValid'] is bool
        ? result['isValid'] as bool
        : false;
    final reason = result['reason']?.toString().trim() ?? '';
    return RecipeContentValidationResult(
      isValid: isValid,
      message: isValid
          ? ''
          : reason.isEmpty
          ? fallbackMessage
          : reason,
    );
  }

  /// Extracts JSON text from OpenAI response structure.
  ///
  /// Traverses the response output array to find the first non-empty text content,
  /// handling both nested and direct output formats.
  String _extractOutputText(Map<String, dynamic> decoded) {
    final output = decoded['output'] as List<dynamic>? ?? const [];
    // Search through output items for text content
    for (final item in output.whereType<Map<String, dynamic>>()) {
      final content = item['content'] as List<dynamic>? ?? const [];
      for (final part in content.whereType<Map<String, dynamic>>()) {
        final text = part['text'];
        if (text is String && text.trim().isNotEmpty) return text;
      }
    }

    // Fallback to direct output_text field
    final direct = decoded['output_text'];
    if (direct is String && direct.trim().isNotEmpty) return direct;
    throw StateError('OpenAI response did not include JSON.');
  }

  /// Determines MIME type from file path extension.
  ///
  /// Returns appropriate MIME type for PNG, WEBP, or defaults to JPEG.
  String _mimeTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  /// Retrieves and validates the OpenAI API key from environment configuration.
  ///
  /// Throws a state error if the API key is missing or empty.
  String _apiKey() {
    final apiKey = EnvConfig.openAiApiKey.trim();
    if (apiKey.isEmpty) {
      throw StateError('OPENAI_API_KEY is missing.');
    }
    return apiKey;
  }
}

/// JSON schema for image-based recipe generation responses.
///
/// Defines the expected structure for recipe extraction from images,
/// including food detection flag, reason, and recipe components.
const Map<String, dynamic> _imageRecipeSchema = {
  'type': 'object',
  'additionalProperties': false,
  'required': [
    'isFood',
    'reason',
    'recipeName',
    'description',
    'ingredients',
    'instructions',
  ],
  'properties': {
    'isFood': {'type': 'boolean'},
    'reason': {'type': 'string'},
    'recipeName': {'type': 'string'},
    'description': {'type': 'string'},
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
  },
};

/// JSON schema for validation responses.
///
/// Defines the standard structure for all validation operations,
/// containing a validity boolean and a reason string.
const Map<String, dynamic> _validationSchema = {
  'type': 'object',
  'additionalProperties': false,
  'required': ['isValid', 'reason'],
  'properties': {
    'isValid': {'type': 'boolean'},
    'reason': {'type': 'string'},
  },
};