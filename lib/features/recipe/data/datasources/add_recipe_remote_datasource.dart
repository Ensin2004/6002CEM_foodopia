import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/services/cloudinary_service.dart';
import '../../domain/entities/add_recipe_basic_info.dart';
import '../models/add_recipe_basic_info_model.dart';
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

    final categories = categorySnapshot.docs
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
      ..sort((first, second) => first.toLowerCase().compareTo(second.toLowerCase()));

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
}
