import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/add_recipe_basic_info.dart';

class AddRecipeBasicInfoModel {
  final String creatorUid;
  final AddRecipeBasicInfo info;
  final List<String> mediaUrls;
  final String visibility;

  const AddRecipeBasicInfoModel({
    required this.creatorUid,
    required this.info,
    required this.mediaUrls,
    this.visibility = 'private',
  });

  Map<String, dynamic> toFirestore() {
    return {
      'creatorUid': creatorUid,
      'media': mediaUrls,
      'name': info.recipeName,
      'otherNames': info.otherNames,
      'categories': info.categories,
      'preparationTime': info.preparationMinutes,
      'difficultyLevel': info.difficultyLevel,
      'servings': info.servings,
      'allergens': info.allergens,
      'visibility': visibility,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

