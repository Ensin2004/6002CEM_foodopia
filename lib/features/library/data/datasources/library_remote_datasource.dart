import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/services/cloudinary_service.dart';
import '../../domain/entities/library_profile.dart';
import '../../domain/entities/library_recipe.dart';
import '../models/library_recipe_model.dart';

// Handles Firebase and Cloudinary access for library profile, connection, recipe, and favourite data.
class LibraryRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  const LibraryRemoteDataSource({required this.firestore, required this.auth});

  Future<LibraryProfile> getProfile() async {
    // Loads the signed-in profile document and falls back to Firebase Auth display data when Firestore fields are missing.
    final uid = _currentUid();
    final doc = await firestore.collection('users').doc(uid).get();
    final data = doc.data() ?? const <String, dynamic>{};
    final name = _firstNotBlank([
      data['name']?.toString(),
      auth.currentUser?.displayName,
      'Foodopia User',
    ]);
    final imageUrl = _firstNotBlank([data['profileImage']?.toString()]);

    return LibraryProfile(
      name: name,
      bio: _firstNotBlank([
        data['bio']?.toString(),
        'Hi, I am $name, a recipe developer',
      ]),
      imageUrl: imageUrl,
      followersCount:
          _intValue(data['followersCount']) ??
          _intValue(data['followerCount']) ??
          0,
      followingCount: await _followingCount(uid, data),
    );
  }

  Future<List<LibraryProfileUser>> getFollowers({String? ownerUid}) async {
    // Finds profiles that have the target account inside the followingCreators subcollection.
    final uid = _targetUid(ownerUid);
    final usersSnapshot = await firestore.collection('users').get();

    final followerIds = <String>{};
    await Future.wait(
      usersSnapshot.docs.where((doc) => doc.id != uid).map((doc) async {
        final followDoc = await doc.reference
            .collection('followingCreators')
            .doc(uid)
            .get();
        if (followDoc.exists) followerIds.add(doc.id);
      }),
    );

    return _getProfileUsers(followerIds);
  }

  Future<List<LibraryProfileUser>> getFollowing({String? ownerUid}) async {
    // Reads creator profiles followed by the target account from the followingCreators subcollection.
    final uid = _targetUid(ownerUid);
    final snapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('followingCreators')
        .get();

    final creatorIds = snapshot.docs
        .map((doc) => doc.data()['creatorUid']?.toString() ?? doc.id)
        .where((id) => _isNotBlank(id) && id != uid)
        .toSet();

    return _getProfileUsers(creatorIds);
  }

  Future<void> updateProfile({
    required String name,
    required String bio,
    File? imageFile,
  }) async {
    // Uploads a replacement profile image when provided before saving profile fields.
    final uid = _currentUid();
    String? imageUrl;

    if (imageFile != null) {
      imageUrl = await CloudinaryService.uploadUserProfileImage(imageFile);
    }

    final nameParts = name.trim().split(RegExp(r'\s+'));
    // Stores split name fields alongside the full name for screens that still read firstName and lastName.
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

  Future<int> _followingCount(String uid, Map<String, dynamic> data) async {
    // Uses cached counters first, then counts following documents when no stored value exists.
    final storedCount =
        _intValue(data['followingCount']) ?? _intValue(data['following']);
    if (storedCount != null && storedCount > 0) return storedCount;

    final snapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('followingCreators')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<List<LibraryProfileUser>> _getProfileUsers(Set<String> uids) async {
    if (uids.isEmpty) return const [];

    final users = <LibraryProfileUser>[];
    // Firestore whereIn supports a maximum of 10 document ids per query.
    for (final chunk in _chunks(uids.toList(), 10)) {
      final snapshot = await firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      users.addAll(snapshot.docs.map(_profileUserFromSnapshot));
    }

    users.sort((first, second) => first.name.compareTo(second.name));
    return users;
  }

  LibraryProfileUser _profileUserFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    // Converts a user document into the compact profile item shown in followers and following lists.
    final data = doc.data() ?? const <String, dynamic>{};
    return LibraryProfileUser(
      uid: doc.id,
      name: _firstNotBlank([
        data['name']?.toString(),
        data['displayName']?.toString(),
        'Foodopia User',
      ]),
      imageUrl: _firstNotBlank([data['profileImage']?.toString()]),
      followerCount:
          _intValue(data['followersCount']) ??
          _intValue(data['followerCount']) ??
          0,
    );
  }

  Future<List<LibraryRecipeModel>> getRecipes() async {
    // Combines owned recipes and saved recipes, then removes duplicates by recipe id.
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
    // Loads one recipe and marks it as favourite when the recipe id exists in saved recipe sources.
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
    // Adds or removes a saved recipe document for the signed-in account.
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
    // Requires an authenticated Firebase account before any library data is requested.
    final uid = auth.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User is not authenticated.',
      );
    }
    return uid;
  }

  String _targetUid(String? ownerUid) {
    // Uses an explicit profile owner when viewing another account, otherwise uses the signed-in account.
    final uid = ownerUid?.trim();
    if (uid != null && uid.isNotEmpty) return uid;
    return _currentUid();
  }

  Future<List<LibraryRecipeModel>> _getSelfRecipes(String uid) async {
    // Loads all recipes created by the signed-in account.
    final snapshot = await firestore
        .collection('recipes')
        .where('creatorUid', isEqualTo: uid)
        .get();

    return Future.wait(
      snapshot.docs.map(
        (doc) => _recipeFromSnapshot(doc, uid: uid, isFollowingAuthor: false),
      ),
    );
  }

  Future<List<LibraryRecipeModel>> _getFollowedRecipes(String uid) async {
    // Loads recipe documents saved through any supported favourite or bookmark source.
    final recipeIds = await _getFollowedRecipeIds(uid);
    if (recipeIds.isEmpty) return const [];

    final recipes = <LibraryRecipeModel>[];
    // Batches recipe id lookups to respect Firestore whereIn limits.
    for (final chunk in _chunks(recipeIds.toList(), 10)) {
      final snapshot = await firestore
          .collection('recipes')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      recipes.addAll(
        await Future.wait(
          snapshot.docs.map(
            (doc) =>
                _recipeFromSnapshot(doc, uid: uid, isFollowingAuthor: true),
          ),
        ),
      );
    }

    return recipes;
  }

  Future<Set<String>> _getFollowedRecipeIds(String uid) async {
    // Collects saved recipe ids from legacy array fields and newer subcollection documents.
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

  Future<LibraryRecipeModel> _recipeFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String uid,
    required bool isFollowingAuthor,
  }) async {
    // Normalizes Firestore recipe fields into the library recipe model used by presentation widgets.
    final data = doc.data() ?? const <String, dynamic>{};
    final creatorUid = data['creatorUid']?.toString() ?? '';
    final creatorData = await _getUserData(creatorUid);
    final rawMedia = _stringList(data['media']);
    final media = rawMedia
        .where((path) => !_isDefaultRecipeImage(path))
        .toList();
    // Supports both display names and stored id lists for categories and allergens.
    final categories = _stringList(data['categories']).isNotEmpty
        ? _stringList(data['categories'])
        : _stringList(data['categoryIds']);
    final allergens = _stringList(data['allergens']).isNotEmpty
        ? _stringList(data['allergens'])
        : _stringList(data['allergenIds']);
    final visibility = data['visibility']?.toString().toLowerCase() ?? '';
    final isPublished = visibility == 'public' || visibility == 'published';
    final title = _firstNotBlank([
      data['name']?.toString(),
      data['recipeName']?.toString(),
      'Untitled Recipe',
    ]);
    final recoveredAiImage = media.isEmpty
        ? await _recoverAiGeneratedRecipeImage(
            recipeRef: doc.reference,
            recipeData: data,
            recipeTitle: title,
            creatorUid: creatorUid,
            currentUid: uid,
          )
        : null;
    final displayMedia = [
      ...media,
      if (recoveredAiImage != null) recoveredAiImage,
    ];
    final imagePath = displayMedia.isNotEmpty
        ? displayMedia.first
        : 'assets/images/meal1.png';
    final createdAt = data['createdAt'];
    final rating =
        _doubleValue(data['averageRating']) ??
        _doubleValue(data['rating']) ??
        0;
    final ratingCount = _intValue(data['ratingCount']) ?? 0;

    return LibraryRecipeModel(
      id: doc.id,
      title: title,
      author: _firstNotBlank([
        data['creatorName']?.toString(),
        data['author']?.toString(),
        creatorData['name']?.toString(),
        creatorData['displayName']?.toString(),
        'You',
      ]),
      publishedAtLabel: _formatPublishedAt(createdAt),
      authorAvatarPath: _firstNotBlank([
        creatorData['profileImage']?.toString(),
      ]),
      imagePath: imagePath,
      imagePaths: displayMedia.isEmpty ? null : displayMedia,
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

  Future<String?> _recoverAiGeneratedRecipeImage({
    required DocumentReference<Map<String, dynamic>> recipeRef,
    required Map<String, dynamic> recipeData,
    required String recipeTitle,
    required String creatorUid,
    required String currentUid,
  }) async {
    if (!_isAiGeneratedRecipe(recipeData) || recipeTitle.trim().isEmpty) {
      return null;
    }

    try {
      final snapshot = await firestore
          .collectionGroup('ai_context')
          .where('generatedRecipe.title', isEqualTo: recipeTitle)
          .limit(10)
          .get()
          .timeout(const Duration(seconds: 8));

      for (final contextDoc in snapshot.docs) {
        final mealPlanRef = contextDoc.reference.parent.parent;
        if (mealPlanRef == null) continue;

        final mealPlan = await mealPlanRef.get();
        final mealData = mealPlan.data();
        if (mealData?['uid']?.toString() != creatorUid) continue;

        final generated = contextDoc.data()['generatedRecipe'];
        final imagePath = generated is Map
            ? generated['imagePath']?.toString().trim() ?? ''
            : '';
        if (!_isRecoverableImagePath(imagePath)) continue;

        if (creatorUid == currentUid) {
          await recipeRef.set({
            'media': [imagePath],
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }

        return imagePath;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  bool _isAiGeneratedRecipe(Map<String, dynamic> data) {
    final sourceMethod = data['sourceMethod']?.toString() ?? '';
    final mode = data['mode']?.toString() ?? '';
    return sourceMethod == 'ai_generated' || mode == 'ai_generated';
  }

  bool _isRecoverableImagePath(String imagePath) {
    if (imagePath.trim().isEmpty || _isDefaultRecipeImage(imagePath)) {
      return false;
    }
    return imagePath.startsWith('http://') || imagePath.startsWith('https://');
  }

  bool _isDefaultRecipeImage(String imagePath) {
    final normalized = imagePath.trim();
    return normalized.isEmpty || normalized == 'assets/images/meal1.png';
  }

  Future<Map<String, dynamic>> _getUserData(String uid) async {
    // Returns empty creator data when a recipe has no valid creator id.
    if (!_isNotBlank(uid)) return const <String, dynamic>{};

    final doc = await firestore.collection('users').doc(uid).get();
    return doc.data() ?? const <String, dynamic>{};
  }

  List<String> _stringList(Object? value) {
    // Converts Firestore array-like values into trimmed non-empty strings.
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim())
          .where(_isNotBlank)
          .toList();
    }
    return const [];
  }

  String _firstNotBlank(List<String?> values) {
    // Selects the first usable fallback string from highest to lowest priority.
    for (final value in values) {
      final normalized = value?.trim() ?? '';
      if (normalized.isNotEmpty) return normalized;
    }
    return '';
  }

  static bool _isNotBlank(String value) => value.trim().isNotEmpty;

  int? _intValue(Object? value) {
    // Accepts numeric Firestore values and parseable numeric strings.
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  double? _doubleValue(Object? value) {
    // Accepts decimal Firestore values and parseable decimal strings.
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  String _difficultyLabel(int? level) {
    // Maps stored difficulty levels to labels shown on library recipe cards.
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
    // Formats Firestore timestamps into short relative labels for recipe cards.
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
    // Builds a placeholder rating distribution until detailed review breakdown data is available.
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
    // Splits long id lists into smaller groups for Firestore query constraints.
    final chunks = <List<T>>[];
    for (var index = 0; index < items.length; index += size) {
      final end = index + size > items.length ? items.length : index + size;
      chunks.add(items.sublist(index, end));
    }
    return chunks;
  }
}
