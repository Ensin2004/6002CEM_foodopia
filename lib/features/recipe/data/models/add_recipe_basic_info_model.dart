import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/add_recipe_basic_info.dart';

/// Converts basic recipe form data into Firestore fields for create and update saves.
class AddRecipeBasicInfoModel {
  final String creatorUid;
  final AddRecipeBasicInfo info;
  final List<String> mediaUrls;
  final List<String> customCategoryIds;
  final List<String> customAllergenIds;

  const AddRecipeBasicInfoModel({
    required this.creatorUid,
    required this.info,
    required this.mediaUrls,
    required this.customCategoryIds,
    required this.customAllergenIds,
  });

  Map<String, dynamic> toFirestore() {
    // New recipe documents include draft status, creator ownership, counters and timestamps.
    return {
      'creatorUid': creatorUid,
      'media': mediaUrls,
      'name': info.recipeName,
      'description': info.description,
      'otherNames': info.otherNames,
      'categoryIds': info.categoryIds,
      'customCategoryIds': customCategoryIds,
      'preparationTime': info.preparationMinutes,
      'difficultyLevel': info.difficultyLevel,
      'servings': info.servings,
      'allergenIds': info.allergenIds,
      'customAllergenIds': customAllergenIds,
      'visibility': info.visibility,
      'sourceMethod': info.isAiGenerated ? 'ai_generated' : 'scratch',
      'mode': info.isAiGenerated ? 'ai_generated' : 'manual',
      'status': 'draft',
      'averageRating': 0.0,
      'ratingCount': 0,
      'commentCount': 0,
      'totalViews': 0,
      'isFinalized': false,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toFirestoreForUpdate() {
    // Updates only replace editable form fields and keep creation metadata unchanged.
    return {
      'media': mediaUrls,
      'name': info.recipeName,
      'description': info.description,
      'otherNames': info.otherNames,
      'categoryIds': info.categoryIds,
      'customCategoryIds': customCategoryIds,
      'preparationTime': info.preparationMinutes,
      'difficultyLevel': info.difficultyLevel,
      'servings': info.servings,
      'allergenIds': info.allergenIds,
      'customAllergenIds': customAllergenIds,
      'visibility': info.visibility,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
