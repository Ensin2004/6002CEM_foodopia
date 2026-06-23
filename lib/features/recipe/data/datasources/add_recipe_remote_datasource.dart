import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/services/openai_ingredient_data_service.dart';
import '../../../../core/services/openai_recipe_content_validation_service.dart';
import '../../../../core/services/recipe_search_service.dart';
import '../../../../core/services/fcm_sender.dart';
import '../../../../core/services/food_search_service.dart';
import '../../../../core/services/unsplash_ingredient_image_service.dart';
import '../../domain/entities/add_recipe_ingredient_data.dart';
import '../../domain/entities/add_recipe_basic_info.dart';
import '../../domain/entities/add_recipe_food_search_result.dart';
import '../../domain/entities/add_recipe_image_result.dart';
import '../../domain/entities/add_recipe_ingredient.dart';
import '../../domain/entities/add_recipe_ingredient_unit.dart';
import '../../domain/entities/add_recipe_instruction.dart';
import '../../domain/entities/add_recipe_option.dart';
import '../../domain/entities/add_recipe_review.dart';
import '../../domain/entities/add_recipe_video_result.dart';
import 'add_recipe_video_datasource.dart';
import '../models/add_recipe_basic_info_model.dart';
import '../models/add_recipe_ingredient_model.dart';
import '../models/add_recipe_instruction_model.dart';
import '../models/add_recipe_review_model.dart';
import '../models/add_recipe_setup_model.dart';

class RecipeContentValidationException implements Exception {
  final String message;

  const RecipeContentValidationException(this.message);

  @override
  String toString() => message;
}

class AddRecipeRemoteDataSource {
  static const List<String> _nutrientKeys = [
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
  ];

  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final FoodSearchService foodSearchService;
  final UnsplashIngredientImageService unsplashIngredientImageService;
  final OpenAiIngredientDataService ingredientAiDataSource;
  final OpenAiRecipeContentValidationService recipeValidationService;
  final AddRecipeVideoDataSource videoDataSource;
  final RecipeSearchService recipeAiSearchService;

  const AddRecipeRemoteDataSource({
    required this.firestore,
    required this.auth,
    required this.foodSearchService,
    required this.unsplashIngredientImageService,
    required this.ingredientAiDataSource,
    required this.recipeValidationService,
    required this.videoDataSource,
    required this.recipeAiSearchService,
  });

  /// Loads active recipe categories, allergens and fixed difficulty levels for setup screens.
  Future<AddRecipeSetupModel> getSetup() async {
    final categories = await _getActiveOptions(configId: 'recipe_categories');
    final allergens = await _getActiveOptions(configId: 'allergies');

    return AddRecipeSetupModel(
      categories: categories,
      allergens: allergens,
      difficultyLevels: const [
        'Novice',
        'Beginner',
        'Intermediate',
        'Advanced',
        'Master',
      ],
    );
  }

  Future<List<AddRecipeOption>> _getActiveOptions({
    required String configId,
  }) async {
    final snapshot = await firestore
        .collection('app_config')
        .doc(configId)
        .collection('items')
        .get();

    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          final isActive = data['isActive'] is bool
              ? data['isActive'] as bool
              : false;
          if (!isActive) return null;

          final name = data['name']?.toString().trim() ?? '';
          if (name.isEmpty) return null;

          return AddRecipeOption(id: doc.id, name: name);
        })
        .whereType<AddRecipeOption>()
        .toList();
  }

  /// Loads active ingredient units for ingredient selection.
  Future<List<AddRecipeIngredientUnit>> getIngredientUnits() async {
    final categorySnapshot = await firestore
        .collection('app_config')
        .doc('ingredient_units_categories')
        .collection('items')
        .get();

    final activeCategories = <String, String>{};
    for (final doc in categorySnapshot.docs) {
      final data = doc.data();
      final isActive = data['isActive'] is bool
          ? data['isActive'] as bool
          : false;
      final name = data['name']?.toString().trim() ?? '';
      if (isActive && name.isNotEmpty) {
        activeCategories[doc.id] = name;
      }
    }

    final unitSnapshot = await firestore
        .collection('app_config')
        .doc('ingredient_units')
        .collection('items')
        .get();

    return unitSnapshot.docs
        .map((doc) {
          final data = doc.data();
          final isActive = data['isActive'] is bool
              ? data['isActive'] as bool
              : false;
          if (!isActive) return null;

          final name = data['name']?.toString().trim() ?? '';
          if (name.isEmpty) return null;

          final categoryId = data['unitCategory']?.toString().trim() ?? '';
          final categoryName = activeCategories[categoryId];
          if (categoryId.isNotEmpty && categoryName == null) return null;

          return AddRecipeIngredientUnit(
            id: doc.id,
            name: name,
            categoryId: categoryId,
            categoryName: categoryName ?? 'Other',
          );
        })
        .whereType<AddRecipeIngredientUnit>()
        .toList()
      ..sort((first, second) {
        final categoryCompare = first.categoryName.toLowerCase().compareTo(
          second.categoryName.toLowerCase(),
        );
        if (categoryCompare != 0) return categoryCompare;
        return first.name.toLowerCase().compareTo(second.name.toLowerCase());
      });
  }

  /// Searches USDA foods using keywords
  Future<List<AddRecipeFoodSearchResult>> searchFoods(String query) async {
    final foods = await foodSearchService.searchUsdaFoods(query);
    return foods
        .map(
          (food) =>
              AddRecipeFoodSearchResult(fdcId: food.fdcId, name: food.name),
        )
        .toList();
  }

  Future<Map<String, dynamic>?> getFoodLabelNutrients(int fdcId) {
    return foodSearchService.getUsdaLabelNutrients(fdcId);
  }

  Future<String?> getIngredientImageUrl(String ingredientName) {
    return unsplashIngredientImageService.findIngredientImageUrl(
      ingredientName,
    );
  }

  /// Generate draft recipe from video uploaded
  Future<AddRecipeVideoResult> generateRecipeFromVideo(String videoPath) async {
    final result = await videoDataSource.generateFromVideo(videoPath);
    return AddRecipeVideoResult(
      basicInfo: result.basicInfo,
      ingredients: await _ingredientsWithUnsplashImages(result.ingredients),
      instructions: result.instructions,
    );
  }

  Future<AddRecipeImageResult> generateRecipeFromImage(
    File imageFile,
  ) async {
    final units = await getIngredientUnits();
    final draft = await recipeValidationService.generateRecipeFromImage(
      imageFile,
    );
    if (!draft.isFood) {
      throw RecipeContentValidationException(
        draft.reason.isEmpty
            ? 'Please upload a food or cooking image.'
            : draft.reason,
      );
    }

    return AddRecipeImageResult(
      recipeName: draft.recipeName,
      description: draft.description,
      ingredients: await _ingredientsWithUnsplashImages(
        draft.ingredients.map((item) {
          final unitId = _unitIdForName(units, item.unit);
          return AddRecipeIngredient(
            name: item.name,
            amount: item.amount,
            unitId: unitId ?? '',
            customUnit: unitId == null ? item.unit : '',
          );
        }).toList(),
      ),
      instructions: [
        for (var index = 0; index < draft.instructions.length; index++)
          AddRecipeInstruction(
            sectionIndex: null,
            sectionTitle: null,
            stepIndex: index + 1,
            description: draft.instructions[index],
          ),
      ],
    );
  }

  Future<List<AddRecipeIngredient>> _ingredientsWithUnsplashImages(
    List<AddRecipeIngredient> ingredients,
  ) async {
    final enriched = <AddRecipeIngredient>[];

    for (final ingredient in ingredients) {
      final existingImage = ingredient.existingImageUrl?.trim();
      final imageUrl = existingImage == null || existingImage.isEmpty
          ? await getIngredientImageUrl(ingredient.name)
          : existingImage;

      enriched.add(
        AddRecipeIngredient(
          name: ingredient.name,
          imageFile: ingredient.imageFile,
          existingImageUrl: imageUrl,
          amount: ingredient.amount,
          unitId: ingredient.unitId,
          customUnit: ingredient.customUnit,
          usdaId: ingredient.usdaId,
          usdaNutrients: ingredient.usdaNutrients,
          ingredientCategoryId: ingredient.ingredientCategoryId,
        ),
      );
    }

    return enriched;
  }

  Future<void> validateBasicInfo(AddRecipeBasicInfo info) async {
    final result = await recipeValidationService.validateBasicInfo(info);
    if (!result.isValid) {
      throw RecipeContentValidationException(result.message);
    }
  }

  Future<void> validateIngredients(
    List<AddRecipeIngredient> ingredients,
  ) async {
    final unitNames = await _resolveIngredientUnitNames(ingredients);
    final normalizedIngredients = ingredients.map((ingredient) {
      final displayUnit = ingredient.customUnit.trim().isNotEmpty
          ? ingredient.customUnit.trim()
          : unitNames[ingredient.unitId] ?? ingredient.unitId;
      return AddRecipeIngredient(
        name: ingredient.name,
        amount: ingredient.amount,
        unitId: '',
        customUnit: displayUnit,
      );
    }).toList();
    final result = await recipeValidationService.validateIngredients(
      normalizedIngredients,
    );
    if (!result.isValid) {
      throw RecipeContentValidationException(result.message);
    }
  }

  Future<void> validateInstructions({
    required bool useSections,
    required List<AddRecipeInstruction> instructions,
  }) async {
    final result = await recipeValidationService.validateInstructions(
      useSections: useSections,
      instructions: instructions,
    );
    if (!result.isValid) {
      throw RecipeContentValidationException(result.message);
    }
  }

  Future<void> validateReview(String recipeId) async {
    final review = await getReview(recipeId);
    final result = await recipeValidationService.validateReview(review);
    if (!result.isValid) {
      throw RecipeContentValidationException(result.message);
    }
  }

  /// Saves or updates basic recipe information
  Future<String> saveBasicInfo(AddRecipeBasicInfo info) async {
    final uid = auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User is not authenticated.',
      );
    }

    final mediaUrls = <String>[...info.existingMediaUrls];
    for (final mediaFile in info.mediaFiles) {
      final url = await CloudinaryService.uploadRecipeImage(mediaFile);
      mediaUrls.add(url);
      if (info.isAiGenerated) {
        await _deleteVideoWorkingDirForFile(mediaFile);
      }
    }

    final model = AddRecipeBasicInfoModel(
      creatorUid: uid,
      info: info,
      mediaUrls: mediaUrls,
      customCategoryIds: await _saveCustomItems(
        collectionId: 'custom_categories',
        names: info.customCategories,
      ),
      customAllergenIds: await _saveCustomItems(
        collectionId: 'custom_allergens',
        names: info.customAllergens,
      ),
    );

    final recipeId = info.recipeId?.trim() ?? '';
    if (recipeId.isNotEmpty) {
      final recipeRef = firestore.collection('recipes').doc(recipeId);
      final moderationFields =
          await _pendingModerationFieldsForPublicFinalizedRecipe(
            recipeRef,
            nextVisibility: info.visibility,
          );
      await recipeRef.update({
        ...model.toFirestoreForUpdate(),
        ...moderationFields,
      });
      return recipeId;
    }

    final doc = await firestore.collection('recipes').add(model.toFirestore());
    return doc.id;
  }

  /// Delete working directory after recipe generated from video
  Future<void> _deleteVideoWorkingDirForFile(File file) async {
    final parent = file.parent;
    final parentName = parent.path.split(RegExp(r'[\\/]')).last;
    if (!parentName.startsWith('foodopia_video_')) return;

    try {
      if (await parent.exists()) {
        await parent.delete(recursive: true);
      }
    } catch (_) {
      // Temporary FFmpeg files won't affect recipe saving after upload.
    }
  }

  /// Saves or updates ingredients and nutrients info
  Future<void> saveIngredients({
    required String recipeId,
    required List<AddRecipeIngredient> ingredients,
  }) async {
    final recipeRef = firestore.collection('recipes').doc(recipeId);
    final ingredientCollection = recipeRef.collection('ingredients');
    final existingIngredients = await ingredientCollection.get();
    final categories = await getActiveIngredientCategories();
    if (categories.isEmpty) {
      throw StateError('No active ingredient categories configured.');
    }
    final unitNames = await _resolveIngredientUnitNames(ingredients);
    final analysisItems = await ingredientAiDataSource.analyzeIngredients(
      ingredients: _ingredientAnalysisInputs(
        ingredients: ingredients,
        unitNames: unitNames,
      ),
      categories: categories,
    );
    final analysisByIndex = {
      for (final item in analysisItems) item.index: item,
    };
    final categoryIds = categories.map((item) => item.id).toSet();
    final othersCategoryId = _getOthersCategoryId(categories);
    final recipeNutrients = _emptyNutrients();
    final batch = firestore.batch();

    for (final doc in existingIngredients.docs) {
      batch.delete(doc.reference);
    }

    for (var index = 0; index < ingredients.length; index++) {
      final ingredient = ingredients[index];
      String? imageUrl = ingredient.existingImageUrl;
      if (ingredient.imageFile != null) {
        imageUrl = await CloudinaryService.uploadIngredientImage(
          ingredient.imageFile!,
        );
      }
      final customUnitId = ingredient.customUnit.isNotEmpty
          ? await _saveCustomUnit(ingredient.customUnit)
          : null;
      final analysis = analysisByIndex[index];
      final existingCategoryId = ingredient.ingredientCategoryId?.trim() ?? '';
      final categoryId = categoryIds.contains(existingCategoryId)
          ? existingCategoryId
          : categoryIds.contains(analysis?.ingredientCategoryId)
          ? analysis!.ingredientCategoryId
          : othersCategoryId;
      final nutrients = _normalizedNutrients(ingredient.usdaNutrients);
      final ingredientNutrients = _mergedNutrients(
        nutrients,
        analysis?.nutrients,
      );
      _addNutrients(recipeNutrients, ingredientNutrients);

      final model = AddRecipeIngredientModel(
        name: ingredient.name,
        imageUrl: imageUrl,
        amount: ingredient.amount,
        unitId: ingredient.unitId.isEmpty ? null : ingredient.unitId,
        customUnitId: customUnitId,
        usdaId: ingredient.usdaId,
        nutrients: ingredientNutrients,
        ingredientCategoryId: categoryId,
      );

      batch.set(ingredientCollection.doc(), model.toFirestore());
    }

    final moderationFields =
        await _pendingModerationFieldsForPublicFinalizedRecipe(recipeRef);
    batch.update(recipeRef, {
      'totalNutrients': recipeNutrients,
      'updatedAt': FieldValue.serverTimestamp(),
      ...moderationFields,
    });

    await batch.commit();
  }

  /// Loads active ingredients categories
  Future<List<AddRecipeIngredientCategory>>
  getActiveIngredientCategories() async {
    final snapshot = await firestore
        .collection('app_config')
        .doc('ingredient_categories')
        .collection('items')
        .get();

    return snapshot.docs
        .map((doc) {
          final data = doc.data();
          final isActive = data['isActive'] is bool
              ? data['isActive'] as bool
              : false;
          final name = data['name']?.toString().trim() ?? '';
          if (!isActive || name.isEmpty) return null;
          return AddRecipeIngredientCategory(id: doc.id, name: name);
        })
        .whereType<AddRecipeIngredientCategory>()
        .toList();
  }

  /// Prepare data for ingredients nutrients calculation
  List<AddRecipeIngredientDataInput> _ingredientAnalysisInputs({
    required List<AddRecipeIngredient> ingredients,
    required Map<String, String> unitNames,
  }) {
    return [
      for (var index = 0; index < ingredients.length; index++)
        AddRecipeIngredientDataInput(
          index: index,
          name: ingredients[index].name,
          amount: ingredients[index].amount,
          unit: ingredients[index].customUnit.trim().isNotEmpty
              ? ingredients[index].customUnit.trim()
              : unitNames[ingredients[index].unitId] ??
                    ingredients[index].unitId,
          usdaNutrients: _normalizedNutrients(ingredients[index].usdaNutrients),
        ),
    ];
  }

  /// Fetch unit names for every ingredient based on unitId
  Future<Map<String, String>> _resolveIngredientUnitNames(
    List<AddRecipeIngredient> ingredients,
  ) async {
    final ids = ingredients
        .map((ingredient) => ingredient.unitId.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    final names = <String, String>{};

    for (final id in ids) {
      final doc = await firestore
          .collection('app_config')
          .doc('ingredient_units')
          .collection('items')
          .doc(id)
          .get();
      final name = doc.data()?['name']?.toString().trim() ?? '';
      names[id] = name.isEmpty ? id : name;
    }

    return names;
  }

  /// Return the id of "others" category
  String? _getOthersCategoryId(List<AddRecipeIngredientCategory> categories) {
    for (final category in categories) {
      if (category.name.trim().toLowerCase() == 'others') {
        return category.id;
      }
    }
    return categories.isEmpty ? null : categories.first.id;
  }

  /// Normalized the key in USDA's results to fetch relevant nutrients data
  Map<String, dynamic>? _normalizedNutrients(Map<String, dynamic>? nutrients) {
    if (nutrients == null || nutrients.isEmpty) return null;

    final normalized = {
      'calories': _nutrientValue(nutrients, const [
        'calories',
        'calorie',
        'energy',
      ]),
      'carbohydrates': _nutrientValue(nutrients, const [
        'carbohydrates',
        'carbohydrate',
        'carbs',
      ]),
      'fat': _nutrientValue(nutrients, const ['fat', 'fats', 'totalFat']),
      'protein': _nutrientValue(nutrients, const ['protein', 'proteins']),
      'fiber': _nutrientValue(nutrients, const ['fiber', 'dietaryFiber']),
      'water': _nutrientValue(nutrients, const ['water', 'moisture']),
      'sodium': _nutrientValue(nutrients, const ['sodium']),
      'potassium': _nutrientValue(nutrients, const ['potassium']),
      'calcium': _nutrientValue(nutrients, const ['calcium']),
      'iron': _nutrientValue(nutrients, const ['iron']),
      'magnesium': _nutrientValue(nutrients, const ['magnesium']),
      'phosphorus': _nutrientValue(nutrients, const [
        'phosphorus',
        'phosphorous',
      ]),
      'zinc': _nutrientValue(nutrients, const ['zinc']),
      'vitaminA': _nutrientValue(nutrients, const [
        'vitaminA',
        'vitaminARAE',
        'retinol',
      ]),
      'vitaminC': _nutrientValue(nutrients, const ['vitaminC', 'ascorbic']),
      'vitaminD': _nutrientValue(nutrients, const ['vitaminD']),
      'vitaminE': _nutrientValue(nutrients, const [
        'vitaminE',
        'alphatocopherol',
        'tocopherol',
      ]),
      'vitaminK': _nutrientValue(nutrients, const ['vitaminK']),
      'vitaminB1': _nutrientValue(nutrients, const [
        'vitaminB1',
        'thiamin',
        'thiamine',
      ]),
      'vitaminB2': _nutrientValue(nutrients, const ['vitaminB2', 'riboflavin']),
      'vitaminB3': _nutrientValue(nutrients, const ['vitaminB3', 'niacin']),
      'vitaminB6': _nutrientValue(nutrients, const ['vitaminB6']),
      'vitaminB9': _nutrientValue(nutrients, const [
        'vitaminB9',
        'folate',
        'folicAcid',
      ]),
      'vitaminB12': _nutrientValue(nutrients, const [
        'vitaminB12',
        'cobalamin',
      ]),
    };

    if (normalized.values.every((value) => value == 0)) return null;
    return normalized;
  }

  Map<String, dynamic>? _mergedNutrients(
    Map<String, dynamic>? preferred,
    Map<String, dynamic>? fallback,
  ) {
    if (preferred == null && fallback == null) return null;

    final merged = <String, dynamic>{};
    for (final key in _nutrientKeys) {
      final preferredValue = _numericValue(preferred?[key]);
      final fallbackValue = _numericValue(fallback?[key]);
      merged[key] = preferredValue > 0 ? preferredValue : fallbackValue;
    }

    if (merged.values.every((value) => _numericValue(value) == 0)) return null;
    return merged;
  }

  /// Fetch nutrients data
  double _nutrientValue(Map<String, dynamic> nutrients, List<String> keys) {
    for (final entry in nutrients.entries) {
      final normalizedKey = entry.key.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9]'),
        '',
      );
      for (final key in keys) {
        final targetKey = key.toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]'),
          '',
        );
        if (_nutrientKeyMatches(normalizedKey, targetKey)) {
          return _numericValue(entry.value);
        }
      }
    }
    return 0;
  }

  bool _nutrientKeyMatches(String normalizedKey, String targetKey) {
    if (normalizedKey == targetKey) return true;
    if (targetKey.startsWith('vitaminb')) return false;
    return normalizedKey.contains(targetKey);
  }

  double _numericValue(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is Map) {
      return _numericValue(value['value'] ?? value['amount']);
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Map<String, dynamic> _emptyNutrients() {
    return {for (final key in _nutrientKeys) key: 0.0};
  }

  /// Add nutrients together to get total nutrients
  void _addNutrients(
    Map<String, dynamic> total,
    Map<String, dynamic>? nutrients,
  ) {
    if (nutrients == null) return;
    for (final key in _nutrientKeys) {
      total[key] = _numericValue(total[key]) + _numericValue(nutrients[key]);
    }
  }

  /// Save custom unit in Firestore
  Future<String> _saveCustomUnit(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return '';

    final collection = firestore
        .collection('custom')
        .doc('custom_units')
        .collection('items');

    final existing = await collection
        .where('name', isEqualTo: trimmedName)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }

    final doc = await collection.add({
      'name': trimmedName,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Save custom category or allergen info in Firestore
  Future<List<String>> _saveCustomItems({
    required String collectionId,
    required List<String> names,
  }) async {
    final ids = <String>[];
    final seenNames = <String>{};

    for (final name in names) {
      final trimmedName = name.trim();
      final normalizedName = trimmedName.toLowerCase();
      if (trimmedName.isEmpty || seenNames.contains(normalizedName)) continue;

      seenNames.add(normalizedName);
      ids.add(
        await _saveCustomItem(collectionId: collectionId, name: trimmedName),
      );
    }

    return ids;
  }

  Future<String> _saveCustomItem({
    required String collectionId,
    required String name,
  }) async {
    final collection = firestore
        .collection('custom')
        .doc(collectionId)
        .collection('items');

    final existing = await collection.where('isActive', isEqualTo: true).get();
    final normalizedName = _normalizeCategoryName(name);
    for (final doc in existing.docs) {
      final existingName = doc.data()['name']?.toString() ?? '';
      if (_normalizeCategoryName(existingName) == normalizedName) {
        return doc.id;
      }
    }

    final doc = await collection.add({
      'name': name,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Saves or updates instructions
  Future<void> saveInstructions({
    required String recipeId,
    required bool useSections,
    required List<AddRecipeInstruction> instructions,
  }) async {
    final recipeRef = firestore.collection('recipes').doc(recipeId);
    final instructionCollection = recipeRef.collection('instructions');
    final existingInstructions = await instructionCollection.get();
    final batch = firestore.batch();

    for (final doc in existingInstructions.docs) {
      batch.delete(doc.reference);
    }

    for (final instruction in instructions) {
      String? stepImageUrl = instruction.existingStepImageUrl;
      if (instruction.stepImageFile != null) {
        stepImageUrl = await CloudinaryService.uploadInstructionImage(
          instruction.stepImageFile!,
        );
      }

      final model = AddRecipeInstructionModel(
        sectionIndex: instruction.sectionIndex,
        sectionTitle: instruction.sectionTitle,
        stepIndex: instruction.stepIndex,
        stepImage: stepImageUrl,
        description: instruction.description,
      );

      batch.set(instructionCollection.doc(), model.toFirestore());
    }

    final moderationFields =
        await _pendingModerationFieldsForPublicFinalizedRecipe(recipeRef);
    batch.update(recipeRef, {
      'instructionUseSection': useSections,
      'updatedAt': FieldValue.serverTimestamp(),
      ...moderationFields,
    });

    await batch.commit();
  }

  /// Loads recipe basic info, ingredient and instruction for review.
  Future<AddRecipeReviewModel> getReview(String recipeId) async {
    final recipeDoc = await firestore.collection('recipes').doc(recipeId).get();
    final recipe = recipeDoc.data();
    if (!recipeDoc.exists || recipe == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Recipe not found.',
      );
    }

    final ingredientsSnapshot = await recipeDoc.reference
        .collection('ingredients')
        .get();
    final instructionsSnapshot = await recipeDoc.reference
        .collection('instructions')
        .get();

    final categories = await _resolveOptionNames(
      optionIds: _stringList(recipe['categoryIds']),
      configId: 'recipe_categories',
      customIds: _stringList(recipe['customCategoryIds']),
      customCollectionId: 'custom_categories',
    );
    final allergens = await _resolveOptionNames(
      optionIds: _stringList(recipe['allergenIds']),
      configId: 'allergies',
      customIds: _stringList(recipe['customAllergenIds']),
      customCollectionId: 'custom_allergens',
    );

    final ingredients = <AddRecipeReviewIngredient>[];
    for (final doc in ingredientsSnapshot.docs) {
      final data = doc.data();
      ingredients.add(
        AddRecipeReviewIngredient(
          name: data['name']?.toString() ?? '',
          image: data['image']?.toString() ?? '',
          amount: _displayAmount(data['amount']),
          unit: await _resolveIngredientUnitName(
            unitId: data['unitId']?.toString() ?? '',
            customUnitId: data['customUnitId']?.toString() ?? '',
          ),
          usdaId: _nullOrInt(data['usda_id']),
          nutrients: data['nutrients'] is Map<String, dynamic>
              ? data['nutrients'] as Map<String, dynamic>
              : null,
          ingredientCategoryId: data['ingredient_categories_id']
              ?.toString()
              .trim(),
        ),
      );
    }

    final instructions =
        instructionsSnapshot.docs.map((doc) {
          final data = doc.data();
          return AddRecipeReviewInstruction(
            sectionIndex: _nullOrInt(data['sectionIndex']),
            sectionTitle: data['sectionTitle']?.toString(),
            stepIndex: _intValue(data['stepIndex']),
            image: data['stepImage']?.toString() ?? '',
            description: data['description']?.toString() ?? '',
          );
        }).toList()..sort((first, second) {
          final firstSection = first.sectionIndex ?? 0;
          final secondSection = second.sectionIndex ?? 0;
          final sectionCompare = firstSection.compareTo(secondSection);
          if (sectionCompare != 0) return sectionCompare;
          return first.stepIndex.compareTo(second.stepIndex);
        });

    return AddRecipeReviewModel.fromParts(
      recipeId: recipeId,
      recipe: recipe,
      categories: categories,
      allergens: allergens,
      ingredients: ingredients,
      instructions: instructions,
    );
  }

  /// Updates recipe visibility and notifies followers when a finalized recipe becomes public.
  Future<void> updateVisibility({
    required String recipeId,
    required String visibility,
  }) async {
    final recipeRef = firestore.collection('recipes').doc(recipeId);
    final snapshot = await recipeRef.get();
    final previousVisibility = snapshot.data()?['visibility']?.toString();

    final shouldMarkPendingReview =
        visibility == 'public' && _isFinalizedRecipe(snapshot.data());
    await recipeRef.update({
      'visibility': visibility,
      'updatedAt': FieldValue.serverTimestamp(),
      if (shouldMarkPendingReview) ...{
        'moderationStatus': 'Pending',
        'moderationHiddenReason': FieldValue.delete(),
        'moderationHiddenAt': FieldValue.delete(),
      },
    });

    if (visibility == 'public' &&
        previousVisibility != 'public' &&
        _isFinalizedRecipe(snapshot.data())) {
      final data = snapshot.data() ?? const <String, dynamic>{};
      final recipeOwnerUid = _recipeOwnerUid(
        data,
        fallbackUid: auth.currentUser?.uid ?? '',
      );
      await _notifyFollowersOfNewRecipe(
        recipeOwnerUid: recipeOwnerUid,
        recipeTitle: data['name']?.toString() ?? 'a new recipe',
      );
      await recipeRef.update({
        'publicNotificationSentAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Marks recipe as finalized, alerts admins about new custom categories and sends follower notifications for public recipes.
  Future<void> finalizeRecipe(String recipeId) async {
    final uid = auth.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User is not authenticated.',
      );
    }

    final recipeRef = firestore.collection('recipes').doc(recipeId);
    final snapshot = await recipeRef.get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Recipe not found.',
      );
    }

    final recipeOwnerUid = _recipeOwnerUid(data, fallbackUid: uid);
    if (recipeOwnerUid != uid) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        message: 'Only the recipe creator can save this recipe.',
      );
    }

    final searchText = await _buildRecipeSearchText(recipeRef, data);
    final searchMetadata = await recipeAiSearchService.buildRecipeMetadata(
      searchText,
    );

    final shouldNotifyAdmins = data['visibility']?.toString() == 'public';
    await recipeRef.update({
      'isFinalized': true,
      'tags': searchMetadata.tags,
      'finalizedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (shouldNotifyAdmins) ...{
        'moderationStatus': 'Pending',
        'moderationHiddenReason': FieldValue.delete(),
        'moderationHiddenAt': FieldValue.delete(),
      },
    });

    if (shouldNotifyAdmins) {
      await _notifyAdminsOfRecipeReview(recipeId: recipeId, senderUid: uid);
    }

    await _notifyAdminsOfNewCategories(
      recipeId: recipeId,
      recipeData: data,
      recipeOwnerUid: recipeOwnerUid,
    );

    if (data['visibility']?.toString() == 'public' &&
        !_hasSentPublicNotification(data)) {
      await _notifyFollowersOfNewRecipe(
        recipeOwnerUid: _recipeOwnerUid(
          data,
          fallbackUid: auth.currentUser?.uid ?? '',
        ),
        recipeTitle: data['name']?.toString() ?? 'a new recipe',
      );
      await recipeRef.update({
        'publicNotificationSentAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<String> _buildRecipeSearchText(
    DocumentReference<Map<String, dynamic>> recipeRef,
    Map<String, dynamic> data,
  ) async {
    final ingredients = await recipeRef.collection('ingredients').get();
    final instructions = await recipeRef.collection('instructions').get();
    final ingredientNames = ingredients.docs
        .map((doc) => doc.data()['name']?.toString().trim() ?? '')
        .where((name) => name.isNotEmpty);
    final instructionText = instructions.docs.expand((doc) {
      final value = doc.data();
      return [value['sectionTitle'], value['description']]
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty);
    });
    return [
          data['name'],
          data['description'],
          ...((data['otherNames'] as List<dynamic>?) ?? const []),
          ...ingredientNames,
          ...instructionText,
        ]
        .map((value) => value?.toString().trim() ?? '')
        .where((value) => value.isNotEmpty)
        .join('\n');
  }

  /// Return recipe owner id
  String _recipeOwnerUid(
    Map<String, dynamic> data, {
    required String fallbackUid,
  }) {
    final creatorId = data['creatorId']?.toString().trim() ?? '';
    if (creatorId.isNotEmpty) return creatorId;

    final creatorUid = data['creatorUid']?.toString().trim() ?? '';
    if (creatorUid.isNotEmpty) return creatorUid;

    return fallbackUid;
  }

  bool _isFinalizedRecipe(Map<String, dynamic>? data) {
    return data?['isFinalized'] != false;
  }

  Future<Map<String, dynamic>> _pendingModerationFieldsForPublicFinalizedRecipe(
    DocumentReference<Map<String, dynamic>> recipeRef, {
    String? nextVisibility,
  }) async {
    final snapshot = await recipeRef.get();
    final data = snapshot.data();
    final visibility = nextVisibility ?? data?['visibility']?.toString();
    if (visibility == 'public' && _isFinalizedRecipe(data)) {
      return {
        'moderationStatus': 'Pending',
        'moderationHiddenReason': FieldValue.delete(),
        'moderationHiddenAt': FieldValue.delete(),
      };
    }
    return const {};
  }

  Future<void> _notifyAdminsOfRecipeReview({
    required String recipeId,
    required String senderUid,
  }) async {
    try {
      final admins = await firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();
      const title = 'Recipe Review';
      const message = 'You have a new recipe waiting to be reviewed';

      for (final admin in admins.docs) {
        final adminUid = admin.id;
        if (adminUid.isEmpty || adminUid == senderUid) continue;

        final notificationRef = await firestore
            .collection('users')
            .doc(adminUid)
            .collection('notifications')
            .add({
              'type': 'recipeReview',
              'title': title,
              'message': message,
              'isRead': false,
              'senderUid': senderUid,
              'recipeId': recipeId,
              'createdAt': FieldValue.serverTimestamp(),
            });

        if (!await _isNotificationEnabled(
          receiverUid: adminUid,
          preferenceId: 'recipe_review_notification',
        )) {
          continue;
        }

        await _sendPushToUser(
          receiverUid: adminUid,
          title: title,
          message: message,
          data: {
            'type': 'recipeReview',
            'notificationId': notificationRef.id,
            'senderUid': senderUid,
            'recipeId': recipeId,
          },
        );
      }
    } on FirebaseException {
      // Recipe saves should remain successful if admin notification fails.
    }
  }

  bool _hasSentPublicNotification(Map<String, dynamic>? data) {
    return data?['publicNotificationSentAt'] != null;
  }

  /// Notify followers when new public recipe created
  Future<void> _notifyFollowersOfNewRecipe({
    required String recipeOwnerUid,
    required String recipeTitle,
  }) async {
    if (recipeOwnerUid.isEmpty) return;
    try {
      final creatorName = await _currentUserName(recipeOwnerUid);
      final followerUids = await _getFollowerUids(recipeOwnerUid);

      for (final followerUid in followerUids) {
        final notificationRef = await firestore
            .collection('users')
            .doc(followerUid)
            .collection('notifications')
            .add({
              'type': 'newRecipe',
              'title': 'New Recipe',
              'message': '$creatorName posted $recipeTitle.',
              'isRead': false,
              'senderUid': recipeOwnerUid,
              'createdAt': FieldValue.serverTimestamp(),
            });
        if (!await _isNotificationEnabled(
          receiverUid: followerUid,
          preferenceId: 'new_recipe_notification',
        )) {
          continue;
        }

        await _sendPushToUser(
          receiverUid: followerUid,
          title: 'New Recipe',
          message: '$creatorName posted $recipeTitle.',
          data: {
            'type': 'newRecipe',
            'notificationId': notificationRef.id,
            'senderUid': recipeOwnerUid,
          },
        );
      }
    } on FirebaseException {
      // Best-effort notification fan-out.
    }
  }

  /// Notify admin about new custom categories
  Future<void> _notifyAdminsOfNewCategories({
    required String recipeId,
    required Map<String, dynamic> recipeData,
    required String recipeOwnerUid,
  }) async {
    try {
      final customCategoryNames = await _resolveCustomItemNames(
        collectionId: 'custom_categories',
        customIds: _stringList(recipeData['customCategoryIds']),
      );
      if (customCategoryNames.isEmpty) return;

      final alreadySent = _stringList(
        recipeData['adminCategoryNotificationKeys'],
      ).toSet();
      final existingCategoryNames = await _existingCategoryNamesForOtherRecipes(
        recipeId,
      );
      final newCategories = <String, String>{};

      for (final categoryName in customCategoryNames) {
        final normalizedName = _normalizeCategoryName(categoryName);
        if (normalizedName.isEmpty ||
            alreadySent.contains(normalizedName) ||
            existingCategoryNames.contains(normalizedName)) {
          continue;
        }
        newCategories[normalizedName] = categoryName.trim();
      }

      if (newCategories.isEmpty) return;

      final creatorName = await _currentUserName(recipeOwnerUid);
      for (final entry in newCategories.entries) {
        await _notifyAdminsOfNewCategory(
          categoryName: entry.value,
          recipeId: recipeId,
          senderUid: recipeOwnerUid,
          senderName: creatorName,
        );
      }

      await firestore.collection('recipes').doc(recipeId).set({
        'adminCategoryNotificationKeys': FieldValue.arrayUnion(
          newCategories.keys.toList(growable: false),
        ),
      }, SetOptions(merge: true));
    } on FirebaseException {
      // Admin category notifications are best-effort.
    }
  }

  Future<Set<String>> _existingCategoryNamesForOtherRecipes(
    String recipeId,
  ) async {
    final names = <String>{};
    final configNames = await _recipeCategoryNamesById();
    names.addAll(configNames.values.map(_normalizeCategoryName));

    final recipeSnapshot = await firestore.collection('recipes').get();
    final customCategoryIds = <String>{};

    for (final doc in recipeSnapshot.docs) {
      if (doc.id == recipeId) continue;
      final data = doc.data();
      for (final categoryId in _stringList(data['categoryIds'])) {
        final categoryName = configNames[categoryId] ?? categoryId;
        names.add(_normalizeCategoryName(categoryName));
      }
      customCategoryIds.addAll(_stringList(data['customCategoryIds']));
    }

    final customNames = await _resolveCustomItemNames(
      collectionId: 'custom_categories',
      customIds: customCategoryIds.toList(growable: false),
    );
    names.addAll(customNames.map(_normalizeCategoryName));
    names.remove('');
    return names;
  }

  Future<Map<String, String>> _recipeCategoryNamesById() async {
    final snapshot = await firestore
        .collection('app_config')
        .doc('recipe_categories')
        .collection('items')
        .get();

    return {
      for (final doc in snapshot.docs)
        if ((doc.data()['name']?.toString().trim() ?? '').isNotEmpty)
          doc.id: doc.data()['name']!.toString().trim(),
    };
  }

  Future<List<String>> _resolveCustomItemNames({
    required String collectionId,
    required List<String> customIds,
  }) async {
    final names = <String>[];
    for (final customId in customIds) {
      final trimmedId = customId.trim();
      if (trimmedId.isEmpty) continue;
      final doc = await firestore
          .collection('custom')
          .doc(collectionId)
          .collection('items')
          .doc(trimmedId)
          .get();
      final name = doc.data()?['name']?.toString().trim() ?? '';
      if (name.isNotEmpty) names.add(name);
    }
    return names;
  }

  Future<void> _notifyAdminsOfNewCategory({
    required String categoryName,
    required String recipeId,
    required String senderUid,
    required String senderName,
  }) async {
    final admins = await firestore
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .get();
    final title = 'New Category';
    final message = '$senderName added new category $categoryName.';

    for (final admin in admins.docs) {
      final adminUid = admin.id;
      if (adminUid.isEmpty || adminUid == senderUid) continue;

      final notificationRef = await firestore
          .collection('users')
          .doc(adminUid)
          .collection('notifications')
          .add({
            'type': 'newCategory',
            'title': title,
            'message': message,
            'isRead': false,
            'senderUid': senderUid,
            'recipeId': recipeId,
            'categoryName': categoryName,
            'createdAt': FieldValue.serverTimestamp(),
          });

      if (!await _isNotificationEnabled(
        receiverUid: adminUid,
        preferenceId: 'new_category_notification',
      )) {
        continue;
      }

      await _sendPushToUser(
        receiverUid: adminUid,
        title: title,
        message: message,
        data: {
          'type': 'newCategory',
          'notificationId': notificationRef.id,
          'senderUid': senderUid,
          'recipeId': recipeId,
          'categoryName': categoryName,
        },
      );
    }
  }

  Future<List<String>> _getFollowerUids(String recipeOwnerUid) async {
    final followerUids = <String>[];
    final usersSnapshot = await firestore.collection('users').get();

    for (final userDoc in usersSnapshot.docs) {
      final followerUid = userDoc.id;
      if (followerUid.isEmpty || followerUid == recipeOwnerUid) continue;

      final followingDoc = await firestore
          .collection('users')
          .doc(followerUid)
          .collection('followingCreators')
          .doc(recipeOwnerUid)
          .get();

      if (followingDoc.exists) {
        followerUids.add(followerUid);
      }
    }

    return followerUids;
  }

  Future<bool> _isNotificationEnabled({
    required String receiverUid,
    required String preferenceId,
  }) async {
    final preferenceDoc = await firestore
        .collection('users')
        .doc(receiverUid)
        .collection('notification_preferences')
        .doc(preferenceId)
        .get();
    final enabled = preferenceDoc.data()?['enabled'];
    return enabled is bool ? enabled : true;
  }

  Future<void> _sendPushToUser({
    required String receiverUid,
    required String title,
    required String message,
    required Map<String, dynamic> data,
  }) async {
    try {
      final userDoc = await firestore
          .collection('users')
          .doc(receiverUid)
          .get();
      final rawTokens = userDoc.data()?['fcmTokens'];
      final tokens = rawTokens is Iterable
          ? rawTokens
                .map((token) => token?.toString().trim() ?? '')
                .where((token) => token.isNotEmpty)
                .toSet()
          : <String>{};

      for (final token in tokens) {
        await FcmSender.instance.sendToToken(
          deviceToken: token,
          title: title,
          body: message,
          data: data,
        );
      }
    } catch (_) {
      // Push sending is best-effort; the Firestore notification remains saved.
    }
  }

  Future<String> _currentUserName(String uid) async {
    final doc = await firestore.collection('users').doc(uid).get();
    final name = doc.data()?['name']?.toString().trim() ?? '';
    return name.isEmpty ? 'Someone' : name;
  }

  /// Deletes recipe and its ingredients, instructions, ratings, comments, replies and nested like records.
  Future<void> deleteRecipe(String recipeId) async {
    final uid = auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User is not authenticated.',
      );
    }

    final recipeRef = firestore.collection('recipes').doc(recipeId);
    final snapshot = await recipeRef.get();
    if (!snapshot.exists) {
      throw StateError('Recipe not found');
    }

    final data = snapshot.data() ?? {};
    final creatorUid = data['creatorUid']?.toString().trim() ?? '';
    if (creatorUid != uid) {
      throw StateError('Only the recipe creator can delete this recipe.');
    }

    await _deleteCollection(recipeRef.collection('ingredients'));
    await _deleteCollection(recipeRef.collection('instructions'));
    await _deleteCollection(recipeRef.collection('ratings'));
    await _deleteComments(recipeRef.collection('comments'));
    await recipeRef.delete();
  }

  Future<void> _deleteComments(
    CollectionReference<Map<String, dynamic>> comments,
  ) async {
    final snapshot = await comments.get();
    for (final comment in snapshot.docs) {
      await _deleteCollection(comment.reference.collection('likedBy'));
      await _deleteReplies(comment.reference.collection('replies'));
      await comment.reference.delete();
    }
  }

  Future<void> _deleteReplies(
    CollectionReference<Map<String, dynamic>> replies,
  ) async {
    final snapshot = await replies.get();
    for (final reply in snapshot.docs) {
      await _deleteCollection(reply.reference.collection('likedBy'));
      await _deleteReplies(reply.reference.collection('replies'));
      await reply.reference.delete();
    }
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    const batchSize = 400;
    while (true) {
      final snapshot = await collection.limit(batchSize).get();
      if (snapshot.docs.isEmpty) return;

      final batch = firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  /// Marks recipe as completed.
  Future<void> completeRecipe({
    required String recipeId,
    required String mode,
  }) async {
    await firestore.collection('recipes').doc(recipeId).update({
      'mode': mode,
      'status': 'saved',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await finalizeRecipe(recipeId);
  }

  Future<List<String>> _resolveOptionNames({
    required List<String> optionIds,
    required String configId,
    required List<String> customIds,
    required String customCollectionId,
  }) async {
    final names = <String>[];
    for (final optionId in optionIds) {
      final doc = await firestore
          .collection('app_config')
          .doc(configId)
          .collection('items')
          .doc(optionId)
          .get();
      final data = doc.data();
      final isActive = data?['isActive'] is bool
          ? data!['isActive'] as bool
          : true;
      if (!isActive) continue;

      final name = data?['name']?.toString().trim() ?? '';
      names.add(name.isEmpty ? optionId : name);
    }
    for (final customId in customIds) {
      final doc = await firestore
          .collection('custom')
          .doc(customCollectionId)
          .collection('items')
          .doc(customId)
          .get();
      final name = doc.data()?['name']?.toString().trim() ?? '';
      names.add(name.isEmpty ? customId : name);
    }
    return names;
  }

  Future<String> _resolveIngredientUnitName({
    required String unitId,
    required String customUnitId,
  }) async {
    if (unitId.isNotEmpty) {
      final doc = await firestore
          .collection('app_config')
          .doc('ingredient_units')
          .collection('items')
          .doc(unitId)
          .get();
      final name = doc.data()?['name']?.toString().trim() ?? '';
      return name.isEmpty ? unitId : name;
    }
    if (customUnitId.isNotEmpty) {
      final doc = await firestore
          .collection('custom')
          .doc('custom_units')
          .collection('items')
          .doc(customUnitId)
          .get();
      final name = doc.data()?['name']?.toString().trim() ?? '';
      return name.isEmpty ? customUnitId : name;
    }
    return '';
  }

  String? _unitIdForName(List<AddRecipeIngredientUnit> units, String name) {
    for (final unit in units) {
      if (unit.name.toLowerCase() == name.trim().toLowerCase()) {
        return unit.id;
      }
    }
    return null;
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }

  String _normalizeCategoryName(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  int? _nullOrInt(dynamic value) {
    if (value == null) return null;
    return _intValue(value);
  }

  String _displayAmount(dynamic value) {
    if (value is int) return value.toString();
    if (value is double && value % 1 == 0) return value.toInt().toString();
    if (value is num) return value.toString();
    return value?.toString() ?? '';
  }
}
