import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/services/fcm_sender.dart';
import '../../../../core/services/food_search_service.dart';
import '../../domain/entities/add_recipe_basic_info.dart';
import '../../domain/entities/add_recipe_food_search_result.dart';
import '../../domain/entities/add_recipe_ingredient.dart';
import '../../domain/entities/add_recipe_ingredient_unit.dart';
import '../../domain/entities/add_recipe_instruction.dart';
import '../../domain/entities/add_recipe_option.dart';
import '../../domain/entities/add_recipe_review.dart';
import '../models/add_recipe_basic_info_model.dart';
import '../models/add_recipe_ingredient_model.dart';
import '../models/add_recipe_instruction_model.dart';
import '../models/add_recipe_review_model.dart';
import '../models/add_recipe_setup_model.dart';

class AddRecipeRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final FoodSearchService foodSearchService;

  const AddRecipeRemoteDataSource({
    required this.firestore,
    required this.auth,
    required this.foodSearchService,
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

  Future<void> saveIngredients({
    required String recipeId,
    required List<AddRecipeIngredient> ingredients,
  }) async {
    final recipeRef = firestore.collection('recipes').doc(recipeId);
    final ingredientCollection = recipeRef.collection('ingredients');
    final existingIngredients = await ingredientCollection.get();
    final batch = firestore.batch();

    for (final doc in existingIngredients.docs) {
      batch.delete(doc.reference);
    }

    for (final ingredient in ingredients) {
      String? imageUrl = ingredient.existingImageUrl;
      if (ingredient.imageFile != null) {
        imageUrl = await CloudinaryService.uploadIngredientImage(
          ingredient.imageFile!,
        );
      }
      final customUnitId = ingredient.customUnit.isNotEmpty
          ? await _saveCustomUnit(ingredient.customUnit)
          : null;

      final model = AddRecipeIngredientModel(
        name: ingredient.name,
        imageUrl: imageUrl,
        amount: ingredient.amount,
        unitId: ingredient.unitId.isEmpty ? null : ingredient.unitId,
        customUnitId: customUnitId,
        usdaId: ingredient.usdaId,
        nutrients: ingredient.usdaNutrients,
      );

      batch.set(ingredientCollection.doc(), model.toFirestore());
    }

    batch.update(recipeRef, {'updatedAt': FieldValue.serverTimestamp()});

    await batch.commit();
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

    final existing = await collection
        .where('name', isEqualTo: name)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
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
