import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/services/openai_video_recipe_service.dart';
import '../../domain/entities/add_recipe_basic_info.dart';
import '../../domain/entities/add_recipe_ingredient.dart';
import '../../domain/entities/add_recipe_ingredient_unit.dart';
import '../../domain/entities/add_recipe_instruction.dart';
import '../../domain/entities/add_recipe_option.dart';
import '../../domain/entities/add_recipe_video_result.dart';

/// Converts uploaded cooking videos into editable recipe data by extracting
/// audio and frames, asking OpenAI for a draft and matching setup options.
class AddRecipeVideoDataSource {
  final FirebaseFirestore firestore;
  final OpenAiVideoRecipeService openAiVideoRecipeService;

  const AddRecipeVideoDataSource({
    required this.firestore,
    required this.openAiVideoRecipeService,
  });

  /// Runs video preprocessing, AI recipe generation, option matching
  /// and ingredient or instruction mapping for the add-recipe flow.
  Future<AddRecipeVideoResult> generateFromVideo(String videoPath) async {
    final workingDir = await _createWorkingDir();
    try {
      // FFmpeg extracts a clean audio track and scene-change frames for AI analysis.
      final audioFile = File('${workingDir.path}/audio.m4a');
      final framePattern = '${workingDir.path}/frame_%03d.jpg';

      await _runFfmpeg(
        '-y -i "${_escape(videoPath)}" -vn -ac 1 -ar 16000 -c:a aac "${_escape(audioFile.path)}"',
      );
      await _runFfmpeg(
        '-y -i "${_escape(videoPath)}" -vf "select=gt(scene\\,0.45),scale=512:-1" -vsync vfr -q:v 8 "${_escape(framePattern)}"',
      );

      final frames =
          workingDir
              .listSync()
              .whereType<File>()
              .where((file) => file.path.toLowerCase().endsWith('.jpg'))
              .toList()
            ..sort((first, second) => first.path.compareTo(second.path));

      final categories = await _getActiveRecipeCategories();
      final units = await _getActiveIngredientUnits();

      // OpenAI turns sampled media evidence into an editable recipe draft.
      final draft = await openAiVideoRecipeService.generateRecipeFromVideo(
        audioFile: audioFile,
        frameFiles: _sampleFrames(frames),
        imageOutputDirectory: workingDir,
      );
      final categoryId = _categoryIdForName(categories, draft.categoryName);

      // Matched categories use configured ids while unmatched categories become custom labels.
      return AddRecipeVideoResult(
        basicInfo: AddRecipeBasicInfo(
          mediaFiles: [
            File(videoPath),
            if (draft.imageFile != null) draft.imageFile!,
          ],
          recipeName: draft.recipeName,
          description: draft.description,
          otherNames: const [],
          categoryIds: categoryId == null ? const [] : [categoryId],
          customCategories: categoryId == null
              ? [draft.categoryName]
              : const [],
          preparationMinutes: draft.preparationMinutes,
          difficultyLevel: draft.difficultyLevel,
          servings: draft.servings.toDouble(),
          allergenIds: const [],
          customAllergens: const [],
          visibility: 'private',
          isAiGenerated: true,
        ),
        ingredients: draft.ingredients.map((item) {
          // Matched units use configured ids while unmatched units become custom units.
          final unitId = _unitIdForName(units, item.unit);
          return AddRecipeIngredient(
            name: item.name,
            amount: item.amount,
            unitId: unitId ?? '',
            customUnit: unitId == null ? item.unit : '',
          );
        }).toList(),
        instructions: [
          // Generated video instructions enter the manual flow as flat numbered steps.
          for (var index = 0; index < draft.instructions.length; index++)
            AddRecipeInstruction(
              sectionIndex: null,
              sectionTitle: null,
              stepIndex: index + 1,
              description: draft.instructions[index],
            ),
        ],
      );
    } catch (_) {
      // Failed generation will also delete working directory to avoid storage leakage.
      await _deleteWorkingDir(workingDir);
      rethrow;
    }
  }

  /// Removes temporary processing files after failed video generation.
  Future<void> _deleteWorkingDir(Directory workingDir) async {
    if (await workingDir.exists()) {
      await workingDir.delete(recursive: true);
    }
  }

  /// Selects a small set of evenly spaced frames for faster visual analysis.
  List<File> _sampleFrames(List<File> frames) {
    if (frames.length <= 15) return frames;

    // Even spacing keeps coverage across the full video without sending every frame.
    final step = frames.length / 15;
    return List.generate(15, (index) => frames[(index * step).floor()]);
  }

  /// Creates a temporary folder for audio, scene frames and generated images.
  Future<Directory> _createWorkingDir() async {
    final baseDir = await getTemporaryDirectory();
    return Directory(
      '${baseDir.path}/foodopia_video_${DateTime.now().microsecondsSinceEpoch}',
    ).create(recursive: true);
  }

  /// Executes an FFmpeg command and reports command logs when processing fails.
  Future<void> _runFfmpeg(String command) async {
    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode)) {
      // FFmpeg logs are included so video processing failures remain diagnosable.
      final logs = await session.getAllLogsAsString();
      throw StateError('FFmpeg failed: $logs');
    }
  }

  /// Loads active recipe categories for matching the AI category name.
  Future<List<AddRecipeOption>> _getActiveRecipeCategories() async {
    final snapshot = await firestore
        .collection('app_config')
        .doc('recipe_categories')
        .collection('items')
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) {
          final name = doc.data()['name']?.toString().trim() ?? '';
          if (name.isEmpty) return null;
          return AddRecipeOption(id: doc.id, name: name);
        })
        .whereType<AddRecipeOption>()
        .toList();
  }

  /// Loads active ingredient units for matching AI ingredient units.
  Future<List<AddRecipeIngredientUnit>> _getActiveIngredientUnits() async {
    final snapshot = await firestore
        .collection('app_config')
        .doc('ingredient_units')
        .collection('items')
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          final name = data['name']?.toString().trim() ?? '';
          if (name.isEmpty) return null;
          return AddRecipeIngredientUnit(
            id: doc.id,
            name: name,
            categoryId: '',
            categoryName: '',
          );
        })
        .whereType<AddRecipeIngredientUnit>()
        .toList();
  }

  /// Finds a configured recipe category id from a display name.
  String? _categoryIdForName(List<AddRecipeOption> categories, String name) {
    for (final category in categories) {
      if (category.name.toLowerCase() == name.trim().toLowerCase()) {
        return category.id;
      }
    }
    return null;
  }

  /// Finds a configured ingredient unit id from a display name.
  String? _unitIdForName(List<AddRecipeIngredientUnit> units, String name) {
    for (final unit in units) {
      if (unit.name.toLowerCase() == name.trim().toLowerCase()) {
        return unit.id;
      }
    }
    return null;
  }

  /// Escapes double quotes before file paths enter FFmpeg command strings.
  String _escape(String path) => path.replaceAll('"', r'\"');
}
