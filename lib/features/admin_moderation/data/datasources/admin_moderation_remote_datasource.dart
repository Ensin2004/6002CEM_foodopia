import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/admin_moderation_recipe_model.dart';

/// Firestore datasource for admin moderation recipes.
class AdminModerationRemoteDataSource {
  /// Firestore dependency.
  final FirebaseFirestore firestore;

  /// Creates an admin moderation remote datasource.
  const AdminModerationRemoteDataSource({required this.firestore});

  /// Watches finalized recipes and resolves creator names from users collection.
  Stream<List<AdminModerationRecipeModel>> watchRecipes() {
    return firestore
        .collection('recipes')
        .where('visibility', isEqualTo: 'public')
        .snapshots()
        .asyncMap((snapshot) {
          return _recipesFromSnapshot(snapshot);
        });
  }

  /// Updates the admin moderation status without changing recipe visibility.
  Future<void> updateRecipeVisibility({
    required String recipeId,
    required bool isPublished,
    String? hiddenReason,
  }) async {
    final recipeRef = firestore.collection('recipes').doc(recipeId);
    final snapshot = await recipeRef.get();
    final data = snapshot.data() ?? const <String, dynamic>{};
    final reason = hiddenReason?.trim() ?? '';

    await recipeRef.update({
      'moderationStatus': isPublished ? 'Pending' : 'Hidden',
      'updatedAt': FieldValue.serverTimestamp(),
      if (isPublished) ...{
        'moderationHiddenReason': FieldValue.delete(),
        'moderationHiddenAt': FieldValue.delete(),
      } else ...{
        'moderationHiddenReason': reason,
        'moderationHiddenAt': FieldValue.serverTimestamp(),
      },
    });

    if (!isPublished) {
      await _notifyCreatorRecipeHidden(
        recipeId: recipeId,
        recipeData: data,
        reason: reason,
      );
    }
  }

  /// Marks a recipe as reviewed.
  Future<void> markRecipeReviewed(String recipeId) async {
    await firestore.collection('recipes').doc(recipeId).update({
      'moderationStatus': 'reviewed',
      'moderationReviewedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<AdminModerationRecipeModel>> _recipesFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    final recipes = <AdminModerationRecipeModel>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['isFinalized'] != true) continue;

      final creatorUid = _creatorUid(data);
      final creatorName = await _creatorName(creatorUid);
      recipes.add(
        AdminModerationRecipeModel.fromFirestore(
          doc: doc,
          creatorName: creatorName,
        ),
      );
    }

    return recipes;
  }

  Future<String> _creatorName(String creatorUid) async {
    if (creatorUid.isEmpty) return 'Unknown creator';

    final doc = await firestore.collection('users').doc(creatorUid).get();
    final data = doc.data() ?? {};
    final name = data['name']?.toString().trim() ?? '';
    return name.isEmpty ? 'Unknown creator' : name;
  }

  String _creatorUid(Map<String, dynamic> data) {
    final creatorId = data['creatorId']?.toString().trim() ?? '';
    if (creatorId.isNotEmpty) return creatorId;
    return data['creatorUid']?.toString().trim() ?? '';
  }

  Future<void> _notifyCreatorRecipeHidden({
    required String recipeId,
    required Map<String, dynamic> recipeData,
    required String reason,
  }) async {
    try {
      final creatorUid = _creatorUid(recipeData);
      if (creatorUid.isEmpty) return;

      final rawRecipeTitle = recipeData['name']?.toString().trim() ?? '';
      final recipeTitle = rawRecipeTitle.isEmpty
          ? 'your recipe'
          : rawRecipeTitle;
      await firestore
          .collection('users')
          .doc(creatorUid)
          .collection('notifications')
          .add({
            'type': 'recipeHidden',
            'title': 'Recipe Hidden',
            'message':
                'Your recipe [$recipeTitle] has been hidden by admin, please review',
            'isRead': false,
            'recipeId': recipeId,
            'reason': reason,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } on FirebaseException {
      // Moderation should remain successful even if notification delivery fails.
    }
  }
}
