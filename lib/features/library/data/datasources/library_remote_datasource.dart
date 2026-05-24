import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/services/cloudinary_service.dart';
import '../../domain/entities/library_profile.dart';
import '../../domain/entities/library_recipe.dart';
import '../models/library_recipe_model.dart';

class LibraryRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  const LibraryRemoteDataSource({required this.firestore, required this.auth});

  Future<LibraryProfile> getProfile() async {
    final uid = _currentUid();
    final doc = await firestore.collection('users').doc(uid).get();
    final data = doc.data() ?? const <String, dynamic>{};
    final name = _firstNotBlank([
      data['name']?.toString(),
      auth.currentUser?.displayName,
      'Foodopia User',
    ]);
    final imageUrl = _firstNotBlank([
      data['profileImage']?.toString(),
      data['profileImageUrl']?.toString(),
      data['photoUrl']?.toString(),
      auth.currentUser?.photoURL,
      'assets/images/onboarding1.png',
    ]);

    return LibraryProfile(
      name: name,
      bio: _firstNotBlank([
        data['bio']?.toString(),
        'Hi, I am $name, a recipe developer',
      ]),
      imageUrl: imageUrl,
      followersCount: _intValue(data['followersCount']) ?? 0,
      followingCount: _intValue(data['followingCount']) ?? 0,
    );
  }

  Future<void> updateProfile({
    required String name,
    required String bio,
    File? imageFile,
  }) async {
    final uid = _currentUid();
    String? imageUrl;

    if (imageFile != null) {
      imageUrl = await CloudinaryService.uploadUserProfileImage(imageFile);
    }

    final nameParts = name.trim().split(RegExp(r'\s+'));
    final firstName = nameParts.isNotEmpty ? nameParts.first : name.trim();
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    final data = <String, dynamic>{
      'name': name.trim(),
      'firstName': firstName,
      'lastName': lastName,
      'bio': bio.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (imageUrl != null && imageUrl.isNotEmpty) {
      data['profileImage'] = imageUrl;
      data['profileImageUrl'] = imageUrl;
    }

    await firestore
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));
    await auth.currentUser?.updateDisplayName(name.trim());
    if (imageUrl != null && imageUrl.isNotEmpty) {
      await auth.currentUser?.updatePhotoURL(imageUrl);
    }
  }

  Future<List<LibraryRecipeModel>> getRecipes() async {
    final uid = _currentUid();
    final selfRecipes = await _getSelfRecipes(uid);
    final followedRecipes = await _getFollowedRecipes(uid);
    final recipesById = <String, LibraryRecipeModel>{};

    for (final recipe in [...selfRecipes, ...followedRecipes]) {
      recipesById[recipe.id] = recipe;
    }

    return recipesById.values.toList();
  }

  Future<LibraryRecipeModel> getRecipeDetail(String recipeId) async {
    final uid = _currentUid();
    final doc = await firestore.collection('recipes').doc(recipeId).get();
    if (!doc.exists) {
      throw StateError('Recipe not found');
    }

    final followedRecipeIds = await _getFollowedRecipeIds(uid);
    return _recipeFromSnapshot(
      doc,
      uid: uid,
      isFollowingAuthor: followedRecipeIds.contains(recipeId),
    );
  }

  Future<void> toggleFavourite({
    required String recipeId,
    required bool isFavourite,
  }) async {
    final uid = _currentUid();
    final favouriteRef = firestore
        .collection('users')
        .doc(uid)
        .collection('saved_recipes')
        .doc(recipeId);

    if (isFavourite) {
      await favouriteRef.set({
        'recipeId': recipeId,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    await favouriteRef.delete();
  }

  String _currentUid() {
    final uid = auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User is not authenticated.',
      );
    }
    return uid;
  }

  Future<List<LibraryRecipeModel>> _getSelfRecipes(String uid) async {
    final snapshot = await firestore
        .collection('recipes')
        .where('creatorUid', isEqualTo: uid)
        .get();

    return snapshot.docs
        .map(
          (doc) => _recipeFromSnapshot(doc, uid: uid, isFollowingAuthor: false),
        )
        .toList();
  }

  Future<List<LibraryRecipeModel>> _getFollowedRecipes(String uid) async {
    final recipeIds = await _getFollowedRecipeIds(uid);
    if (recipeIds.isEmpty) return const [];

    final recipes = <LibraryRecipeModel>[];
    for (final chunk in _chunks(recipeIds.toList(), 10)) {
      final snapshot = await firestore
          .collection('recipes')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      recipes.addAll(
        snapshot.docs.map(
          (doc) => _recipeFromSnapshot(doc, uid: uid, isFollowingAuthor: true),
        ),
      );
    }

    return recipes;
  }

  Future<Set<String>> _getFollowedRecipeIds(String uid) async {
    final ids = <String>{};
    final userDoc = await firestore.collection('users').doc(uid).get();
    final userData = userDoc.data() ?? const <String, dynamic>{};

    for (final field in const [
      'bookmarkedRecipeIds',
      'followingRecipeIds',
      'savedRecipeIds',
      'favoriteRecipeIds',
    ]) {
      final value = userData[field];
      if (value is Iterable) {
        ids.addAll(value.map((item) => item.toString()).where(_isNotBlank));
      }
    }

    for (final collection in const [
      'bookmarks',
      'bookmarked_recipes',
      'saved_recipes',
      'following_recipes',
    ]) {
      final snapshot = await firestore
          .collection('users')
          .doc(uid)
          .collection(collection)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final recipeId = data['recipeId']?.toString() ?? doc.id;
        if (_isNotBlank(recipeId)) ids.add(recipeId);
      }
    }

    return ids;
  }

  LibraryRecipeModel _recipeFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String uid,
    required bool isFollowingAuthor,
  }) {
    final data = doc.data() ?? const <String, dynamic>{};
    final creatorUid = _recipeCreatorUid(data);
    final media = _stringList(data['media']);
    final categories = _stringList(data['categories']).isNotEmpty
        ? _stringList(data['categories'])
        : _stringList(data['categoryIds']);
    final allergens = _stringList(data['allergens']).isNotEmpty
        ? _stringList(data['allergens'])
        : _stringList(data['allergenIds']);
    final visibility = data['visibility']?.toString().toLowerCase() ?? '';
    final isPublished = visibility == 'public' || visibility == 'published';
    final imagePath = media.isNotEmpty
        ? media.first
        : 'assets/images/meal1.png';
    final createdAt = data['createdAt'];
    final rating =
        _doubleValue(data['averageRating']) ??
        _doubleValue(data['rating']) ??
        0;
    final ratingCount = _intValue(data['ratingCount']) ?? 0;

    return LibraryRecipeModel(
      id: doc.id,
      title: _firstNotBlank([
        data['name']?.toString(),
        data['recipeName']?.toString(),
        'Untitled Recipe',
      ]),
      author: _firstNotBlank([
        data['creatorName']?.toString(),
        data['author']?.toString(),
        'You',
      ]),
      publishedAtLabel: _formatPublishedAt(createdAt),
      authorAvatarPath: _firstNotBlank([
        data['creatorAvatar']?.toString(),
        data['authorAvatarPath']?.toString(),
        'assets/images/onboarding1.png',
      ]),
      imagePath: imagePath,
      imagePaths: media.isEmpty ? null : media,
      description: _firstNotBlank([
        data['description']?.toString(),
        categories.isEmpty ? null : categories.join(', '),
        'A recipe from your library.',
      ]),
      category: categories.isEmpty ? 'Uncategorized' : categories.join(', '),
      allergenInfo: allergens.isEmpty
          ? 'No allergens listed'
          : allergens.join(', '),
      totalTime: '${_intValue(data['preparationTime']) ?? 0} min',
      difficulty: _difficultyLabel(_intValue(data['difficultyLevel'])),
      rating: rating,
      ratingCount: ratingCount,
      commentCount: _intValue(data['commentCount']) ?? 0,
      totalViews: _intValue(data['totalViews']) ?? 0,
      isSelfPublished: creatorUid == uid,
      isFollowingAuthor: isFollowingAuthor,
      isPublished: isPublished,
      ingredients: const [],
      instructionSections: const [],
      nutrition: const LibraryNutrition(
        calories: 0,
        carbsGrams: 0,
        proteinGrams: 0,
        fatGrams: 0,
      ),
      community: LibraryCommunity(
        authorBio: '',
        ratingBreakdown: _ratingBreakdown(ratingCount),
        reviews: const [],
        comments: const [],
      ),
      relatedRecipes: const [],
    );
  }

  List<String> _stringList(Object? value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where(_isNotBlank)
          .toList();
    }
    return const [];
  }

  String _firstNotBlank(List<String?> values) {
    for (final value in values) {
      final normalized = value?.trim() ?? '';
      if (normalized.isNotEmpty) return normalized;
    }
    return '';
  }

  String _recipeCreatorUid(Map<String, dynamic> data) {
    return _firstNotBlank([
      data['creatorUid']?.toString(),
      data['creatorId']?.toString(),
      data['userId']?.toString(),
    ]);
  }

  static bool _isNotBlank(String value) => value.trim().isNotEmpty;

  int? _intValue(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  double? _doubleValue(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  String _difficultyLabel(int? level) {
    switch (level) {
      case 1:
        return 'Novice';
      case 2:
        return 'Beginner';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Advanced';
      case 5:
        return 'Master';
      default:
        return 'Easy';
    }
  }

  String _formatPublishedAt(Object? value) {
    if (value is! Timestamp) return 'Just now';

    final date = value.toDate();
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hrs ago';
    if (difference.inDays == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  List<LibraryRatingBreakdown> _ratingBreakdown(int ratingCount) {
    if (ratingCount <= 0) {
      return const [
        LibraryRatingBreakdown(stars: 5, count: 0),
        LibraryRatingBreakdown(stars: 4, count: 0),
        LibraryRatingBreakdown(stars: 3, count: 0),
        LibraryRatingBreakdown(stars: 2, count: 0),
        LibraryRatingBreakdown(stars: 1, count: 0),
      ];
    }

    return [
      LibraryRatingBreakdown(stars: 5, count: ratingCount),
      const LibraryRatingBreakdown(stars: 4, count: 0),
      const LibraryRatingBreakdown(stars: 3, count: 0),
      const LibraryRatingBreakdown(stars: 2, count: 0),
      const LibraryRatingBreakdown(stars: 1, count: 0),
    ];
  }

  List<List<T>> _chunks<T>(List<T> items, int size) {
    final chunks = <List<T>>[];
    for (var index = 0; index < items.length; index += size) {
      final end = index + size > items.length ? items.length : index + size;
      chunks.add(items.sublist(index, end));
    }
    return chunks;
  }
}
