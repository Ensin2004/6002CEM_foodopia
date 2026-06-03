import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/services/openai_ingredient_data_service.dart';
import '../../../../core/services/fcm_sender.dart';
import '../../../../core/services/food_search_service.dart';
import '../../domain/entities/add_recipe_ingredient_data.dart';
import '../../domain/entities/add_recipe_basic_info.dart';
import '../../domain/entities/add_recipe_food_search_result.dart';
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

class AddRecipeRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final FoodSearchService foodSearchService;
  final OpenAiIngredientDataService ingredientAiDataSource;
  final AddRecipeVideoDataSource videoDataSource;

  const AddRecipeRemoteDataSource({
    required this.firestore,
    required this.auth,
    required this.foodSearchService,
    required this.ingredientAiDataSource,
    required this.videoDataSource,
  });

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

  Future<AddRecipeVideoResult> generateRecipeFromVideo(String videoPath) {
    return videoDataSource.generateFromVideo(videoPath);
  }

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
      await firestore
          .collection('recipes')
          .doc(recipeId)
          .update(model.toFirestoreForUpdate());
      return recipeId;
    }

    final doc = await firestore.collection('recipes').add(model.toFirestore());
    return doc.id;
  }

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

  Future<void> saveIngredients({
    required String recipeId,
    required List<AddRecipeIngredient> ingredients,
  }) async {
    final recipeRef = firestore.collection('recipes').doc(recipeId);
    final ingredientCollection = recipeRef.collection('ingredients');
    final existingIngredients = await ingredientCollection.get();
    final categories = await _getActiveIngredientCategories();
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
      final ingredientNutrients = nutrients ?? analysis?.nutrients;
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

    batch.update(recipeRef, {
      'totalNutrients': recipeNutrients,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  Future<List<AddRecipeIngredientCategory>>
  _getActiveIngredientCategories() async {
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

  String? _getOthersCategoryId(List<AddRecipeIngredientCategory> categories) {
    for (final category in categories) {
      if (category.name.trim().toLowerCase() == 'others') {
        return category.id;
      }
    }
    return categories.isEmpty ? null : categories.first.id;
  }

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
    };

    if (normalized.values.every((value) => value == 0)) return null;
    return normalized;
  }

  double _nutrientValue(Map<String, dynamic> nutrients, List<String> keys) {
    for (final entry in nutrients.entries) {
      final normalizedKey = entry.key.toLowerCase().replaceAll(
        RegExp(r'[^a-z]'),
        '',
      );
      for (final key in keys) {
        final targetKey = key.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
        if (normalizedKey == targetKey || normalizedKey.contains(targetKey)) {
          return _numericValue(entry.value);
        }
      }
    }
    return 0;
  }

  double _numericValue(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is Map) {
      return _numericValue(value['value'] ?? value['amount']);
    }
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Map<String, dynamic> _emptyNutrients() {
    return {'calories': 0.0, 'carbohydrates': 0.0, 'fat': 0.0, 'protein': 0.0};
  }

  void _addNutrients(
    Map<String, dynamic> total,
    Map<String, dynamic>? nutrients,
  ) {
    if (nutrients == null) return;
    for (final key in const ['calories', 'carbohydrates', 'fat', 'protein']) {
      total[key] = _numericValue(total[key]) + _numericValue(nutrients[key]);
    }
  }

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

    batch.update(recipeRef, {
      'instructionUseSection': useSections,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

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

  Future<void> updateVisibility({
    required String recipeId,
    required String visibility,
  }) async {
    final recipeRef = firestore.collection('recipes').doc(recipeId);
    final snapshot = await recipeRef.get();
    final previousVisibility = snapshot.data()?['visibility']?.toString();

    await recipeRef.update({
      'visibility': visibility,
      'updatedAt': FieldValue.serverTimestamp(),
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

    await recipeRef.update({
      'isFinalized': true,
      'finalizedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

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

  bool _hasSentPublicNotification(Map<String, dynamic>? data) {
    return data?['publicNotificationSentAt'] != null;
  }

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
      final name = doc.data()?['name']?.toString().trim() ?? '';
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
