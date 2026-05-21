import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/add_recipe_basic_info.dart';

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
      'averageRating': 0.0,
      'ratingCount': 0,
      'commentCount': 0,
      'totalViews': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
