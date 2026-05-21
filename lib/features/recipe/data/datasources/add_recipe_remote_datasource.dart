import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/services/food_search_service.dart';
import '../../domain/entities/add_recipe_basic_info.dart';
import '../../domain/entities/add_recipe_food_search_result.dart';
import '../../domain/entities/add_recipe_ingredient.dart';
import '../../domain/entities/add_recipe_ingredient_unit.dart';
import '../../domain/entities/add_recipe_instruction.dart';
import '../../domain/entities/add_recipe_option.dart';
import '../models/add_recipe_basic_info_model.dart';
import '../models/add_recipe_ingredient_model.dart';
import '../models/add_recipe_instruction_model.dart';
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

    final mediaUrls = <String>[];
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

    final doc = await firestore.collection('recipes').add(model.toFirestore());
    return doc.id;
  }

  Future<void> saveIngredients({
    required String recipeId,
    required List<AddRecipeIngredient> ingredients,
  }) async {
    final recipeRef = firestore.collection('recipes').doc(recipeId);
    final batch = firestore.batch();

    for (final ingredient in ingredients) {
      String? imageUrl;
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

      batch.set(recipeRef.collection('ingredients').doc(), model.toFirestore());
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
      String? stepImageUrl;
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
}
