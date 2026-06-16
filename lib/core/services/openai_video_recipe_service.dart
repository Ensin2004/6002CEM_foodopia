import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../features/recipe/domain/entities/add_recipe_video_result.dart';
import '../config/env_config.dart';

/// Generates a complete recipe draft from extracted audio and frames.
/// 1. Extract info from audio using OpenAI Whisper
/// 2. Extract info from frames using OpenAI GPT-4o-mini
/// 3. Generate recipe draft using OpenAI GPT-4o-mini
/// 4. Generate image using OpenAI GPT-image-2
class OpenAiVideoRecipeService {
  final http.Client client;

  const OpenAiVideoRecipeService({required this.client});

  /// Generates a complete recipe draft from extracted audio and frames.
  Future<AddRecipeVideoDraft> generateRecipeFromVideo({
    required File audioFile,
    required List<File> frameFiles,
    required Directory imageOutputDirectory,
  }) async {
    final transcript = await _transcribeAudio(audioFile);
    final visualNotes = await _analyzeFrames(frameFiles);
    final draft = await _synthesizeRecipe(
      transcript: transcript,
      visualNotes: visualNotes,
    );
    final imageFile = await _generateRecipeImage(
      prompt: draft.imagePrompt,
      outputDirectory: imageOutputDirectory,
    );

    return AddRecipeVideoDraft(
      recipeName: draft.recipeName,
      description: draft.description,
      categoryName: draft.categoryName,
      preparationMinutes: draft.preparationMinutes,
      difficultyLevel: draft.difficultyLevel,
      servings: draft.servings,
      ingredients: draft.ingredients,
      instructions: draft.instructions,
      imagePrompt: draft.imagePrompt,
      imageFile: imageFile,
    );
  }

  /// Extract info from audio using OpenAI Whisper
  Future<String> _transcribeAudio(File audioFile) async {
    final apiKey = _apiKey();
    final request =
        http.MultipartRequest(
            'POST',
            Uri.parse('https://api.openai.com/v1/audio/transcriptions'),
          )
          ..headers['Authorization'] = 'Bearer $apiKey'
          ..fields['model'] = EnvConfig.openAiTranscriptionModel
          ..fields['response_format'] = 'json'
          ..fields['prompt'] =
              'Transcribe only cooking and recipe related speech from this recipe video.'
          ..files.add(
            await http.MultipartFile.fromPath('file', audioFile.path),
          );

    final streamed = await request.send().timeout(const Duration(seconds: 120));
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw StateError('OpenAI transcription failed: $body');
    }
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    return decoded['text']?.toString().trim() ?? '';
  }

  /// Extract info from frames using OpenAI GPT-4o-mini
  Future<String> _analyzeFrames(List<File> frameFiles) async {
    final apiKey = _apiKey();
    if (frameFiles.isEmpty) return '';
    final content = <Map<String, dynamic>>[
      {
        'type': 'input_text',
        'text':
            'Extract recipe related info from these scene-change frames: visible dish, ingredients, amounts if visible, tools, food preparation process, cooking steps, doneness cues, and plating. Return concise notes.',
      },
      for (final frame in frameFiles)
        {
          'type': 'input_image',
          'image_url':
              'data:image/jpeg;base64,${base64Encode(await frame.readAsBytes())}',
          'detail': 'low',
        },
    ];

    final response = await client
        .post(
          Uri.parse('https://api.openai.com/v1/responses'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': EnvConfig.openAiVideoRecipeModel,
            'max_output_tokens': 2500,
            'input': [
              {'role': 'user', 'content': content},
            ],
          }),
        )
        .timeout(const Duration(seconds: 120));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'OpenAI frame info extract request failed: ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return _extractOutputText(decoded);
  }

  /// Generate recipe draft with the extracted info using OpenAI GPT-4o-mini
  Future<AddRecipeVideoDraft> _synthesizeRecipe({
    required String transcript,
    required String visualNotes,
  }) async {
    final apiKey = _apiKey();
    final response = await client
        .post(
          Uri.parse('https://api.openai.com/v1/responses'),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': EnvConfig.openAiVideoRecipeModel,
            'max_output_tokens': 2500,
            'input': [
              {
                'role': 'system',
                'content':
                    'You are Foodopia video recipe AI. Return only valid JSON that matches the requested schema.',
              },
              {
                'role': 'user',
                'content': _buildPrompt(transcript, visualNotes),
              },
            ],
            'text': {
              'format': {
                'type': 'json_schema',
                'name': 'foodopia_video_recipe',
                'schema': _videoRecipeSchema,
                'strict': true,
              },
            },
          }),
        )
        .timeout(const Duration(seconds: 120));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('OpenAI recipe request failed: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final content = _extractOutputText(decoded);
    final payload = jsonDecode(content) as Map<String, dynamic>;
    return _draftFromJson(payload);
  }

  /// Generate image using OpenAI GPT-image-2
  Future<File?> _generateRecipeImage({
    required String prompt,
    required Directory outputDirectory,
  }) async {
    final apiKey = _apiKey();
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
                '$prompt. App recipe card food photography, natural light, appetizing plated dish, no text.',
            'size': '1024x1024',
            'quality': 'low',
            'n': 1,
          }),
        )
        .timeout(const Duration(seconds: 120));

    if (response.statusCode < 200 || response.statusCode >= 300) return null;
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final data = decoded['data'] as List<dynamic>? ?? const [];
    final maps = data.whereType<Map<String, dynamic>>();
    final first = maps.isEmpty ? null : maps.first;
    final b64 = first?['b64_json']?.toString();
    if (b64 == null || b64.isEmpty) return null;

    final file = File('${outputDirectory.path}/recipe_image.png');
    await file.writeAsBytes(base64Decode(b64));
    return file;
  }

  /// Builds the prompt with required info and rules.
  String _buildPrompt(String transcript, String visualNotes) {
    return '''
Use the audio transcript and visual frame notes as references, generate one complete recipe.

Audio transcript: $transcript
Visual notes: $visualNotes

Recipe needs: recipe name, recipe category, short description, preparation time, difficulty level from 1 (Novice) to 5 (Master), number of servings, 4-10 ingredients with amount and unit, 4-10 cooking instructions and a food photography image prompt.
''';
  }

  /// Reads text content from the Responses API output format.
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

  /// Converts the results from JSON into desired format.
  AddRecipeVideoDraft _draftFromJson(Map<String, dynamic> json) {
    final recipeName = json['recipeName']?.toString().trim() ?? 'Video Recipe';

    return AddRecipeVideoDraft(
      recipeName: recipeName,
      description: json['description']?.toString().trim() ?? '',
      categoryName: json['categoryName']?.toString().trim() ?? '',
      preparationMinutes: (json['preparationMinutes'] as num?)?.toInt() ?? 30,
      difficultyLevel: ((json['difficultyLevel'] as num?)?.toInt() ?? 2).clamp(1, 5),
      servings: ((json['servings'] as num?)?.toInt() ?? 2).clamp(1, 99),
      ingredients: (json['ingredients'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => AddRecipeVideoIngredient(
              name: item['name']?.toString().trim() ?? '',
              amount: (item['amount'] as num?)?.toDouble() ?? 0,
              unit: item['unit']?.toString().trim() ?? '',
            ),
          )
          .where((item) => item.name.isNotEmpty)
          .toList(),
      instructions: (json['instructions'] as List<dynamic>? ?? const [])
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      imagePrompt: json['imagePrompt']?.toString().trim() ?? recipeName,
    );
  }

  /// Returns the configured OpenAI API key or stops generation with a clear error.
  String _apiKey() {
    final apiKey = EnvConfig.openAiApiKey.trim();
    if (apiKey.isEmpty) {
      throw StateError(
        'OPENAI_API_KEY is missing. Add it to your dart defines before generating recipe.',
      );
    }
    return apiKey;
  }
}

/// JSON schema for the AI, to ensure the results are provided in correct format.
const Map<String, dynamic> _videoRecipeSchema = {
  'type': 'object',
  'additionalProperties': false,
  'required': [
    'recipeName',
    'description',
    'categoryName',
    'preparationMinutes',
    'difficultyLevel',
    'servings',
    'ingredients',
    'instructions',
    'imagePrompt',
  ],
  'properties': {
    'recipeName': {'type': 'string'},
    'description': {'type': 'string'},
    'categoryName': {'type': 'string'},
    'preparationMinutes': {'type': 'integer'},
    'difficultyLevel': {'type': 'integer', 'minimum': 1, 'maximum': 5},
    'servings': {'type': 'integer'},
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
  },
};
