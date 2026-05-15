import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/services/cloudinary_service.dart';
import '../../domain/entities/add_recipe_basic_info.dart';
import '../../domain/entities/add_recipe_ingredient.dart';
import '../models/add_recipe_basic_info_model.dart';
import '../models/add_recipe_ingredient_model.dart';
import '../models/add_recipe_setup_model.dart';

class AddRecipeRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  const AddRecipeRemoteDataSource({
    required this.firestore,
    required this.auth,
  });

  Future<AddRecipeSetupModel> getSetup() async {
    final categorySnapshot = await firestore
        .collection('app_config')
        .doc('recipe_categories')
        .collection('items')
        .get();

    final categories =
        categorySnapshot.docs
            .map((doc) {
              final data = doc.data();
              final isActive = data['isActive'] is bool
                  ? data['isActive'] as bool
                  : false;
              if (!isActive) return null;

              final name = data['name']?.toString().trim() ?? '';
              if (name.isEmpty) return null;

              return name;
            })
            .whereType<String>()
            .toList()
          ..sort(
            (first, second) =>
                first.toLowerCase().compareTo(second.toLowerCase()),
          );

    return AddRecipeSetupModel(
      categories: categories,
      difficultyLevels: const [
        'Novice',
        'Beginner',
        'Intermediate',
        'Advanced',
        'Master',
      ],
    );
  }

  Future<List<String>> getIngredientUnits() async {
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

          return name;
        })
        .whereType<String>()
        .toList()
      ..sort(
        (first, second) => first.toLowerCase().compareTo(second.toLowerCase()),
      );
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

      final model = AddRecipeIngredientModel(
        name: ingredient.name,
        imageUrl: imageUrl,
        amount: ingredient.amount,
        unit: ingredient.unit,
      );

      batch.set(recipeRef.collection('ingredients').doc(), model.toFirestore());
    }

    batch.update(recipeRef, {'updatedAt': FieldValue.serverTimestamp()});

    await batch.commit();
  }
}
