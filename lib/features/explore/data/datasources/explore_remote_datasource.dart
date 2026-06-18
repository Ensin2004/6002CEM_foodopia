import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/services/fcm_sender.dart';
import '../../domain/entities/explore_recipe.dart';
import '../models/explore_recipe_model.dart';

class ExploreRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  const ExploreRemoteDataSource({required this.firestore, required this.auth});

  Future<List<ExploreRecipeModel>> getRecipes() async {
    final snapshot = await firestore
        .collection('recipes')
        .where('visibility', isEqualTo: 'public')
        .orderBy('updatedAt', descending: true)
        .get();

    final recipes = <ExploreRecipeModel>[];
    for (final doc in snapshot.docs) {
      if (!_isPublicFinalizedRecipe(doc.data())) continue;
      recipes.add(await _recipeFromDoc(doc, includeCommunity: false));
    }
    return recipes;
  }

  Stream<List<ExploreRecipeModel>> watchRecipes() {
    late final StreamController<List<ExploreRecipeModel>> controller;
    final subscriptions = <StreamSubscription<dynamic>>[];
    var isFetching = false;
    var shouldFetchAgain = false;

    Future<void> emitRecipes() async {
      if (isFetching) {
        shouldFetchAgain = true;
        return;
      }
      isFetching = true;
      do {
        shouldFetchAgain = false;
        try {
          controller.add(await getRecipes());
        } catch (error, stackTrace) {
          controller.addError(error, stackTrace);
        }
      } while (shouldFetchAgain && !controller.isClosed);
      isFetching = false;
    }

    controller = StreamController<List<ExploreRecipeModel>>(
      onListen: () {
        subscriptions.add(
          firestore
              .collection('recipes')
              .where('visibility', isEqualTo: 'public')
              .orderBy('updatedAt', descending: true)
              .snapshots()
              .listen((_) => emitRecipes()),
        );
        final uid = auth.currentUser?.uid ?? '';
        if (uid.isNotEmpty) {
          subscriptions.add(
            firestore
                .collection('users')
                .doc(uid)
                .collection('followingCreators')
                .snapshots()
                .listen((_) => emitRecipes()),
          );
          subscriptions.add(
            firestore
                .collection('users')
                .doc(uid)
                .collection('saved_recipes')
                .snapshots()
                .listen((_) => emitRecipes()),
          );
        }
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );
    return controller.stream;
  }

  Stream<ExploreRecipeModel> watchRecipeDetail(String recipeId) {
    final recipeRef = firestore.collection('recipes').doc(recipeId);
    late final StreamController<ExploreRecipeModel> controller;
    final subscriptions = <StreamSubscription<dynamic>>[];
    var isFetching = false;
    var shouldFetchAgain = false;

    Future<void> emitRecipe() async {
      if (isFetching) {
        shouldFetchAgain = true;
        return;
      }
      isFetching = true;
      do {
        shouldFetchAgain = false;
        try {
          final doc = await recipeRef.get();
          if (!doc.exists) {
            controller.addError(StateError('Recipe not found'));
          } else {
            controller.add(await _recipeFromDoc(doc, includeCommunity: true));
          }
        } catch (error, stackTrace) {
          controller.addError(error, stackTrace);
        }
      } while (shouldFetchAgain && !controller.isClosed);
      isFetching = false;
    }

    controller = StreamController<ExploreRecipeModel>(
      onListen: () {
        subscriptions.add(recipeRef.snapshots().listen((_) => emitRecipe()));
        subscriptions.add(
          recipeRef
              .collection('ratings')
              .snapshots()
              .listen((_) => emitRecipe()),
        );
        subscriptions.add(
          recipeRef
              .collection('comments')
              .snapshots()
              .listen((_) => emitRecipe()),
        );
        final uid = auth.currentUser?.uid ?? '';
        if (uid.isNotEmpty) {
          subscriptions.add(
            firestore
                .collection('users')
                .doc(uid)
                .collection('followingCreators')
                .snapshots()
                .listen((_) => emitRecipe()),
          );
          subscriptions.add(
            firestore
                .collection('users')
                .doc(uid)
                .collection('saved_recipes')
                .snapshots()
                .listen((_) => emitRecipe()),
          );
        }
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );
    return controller.stream;
  }

  Future<ExploreRecipeModel> getRecipeDetail(String recipeId) async {
    final doc = await firestore.collection('recipes').doc(recipeId).get();
    if (!doc.exists) {
      throw StateError('Recipe not found');
    }

    return _recipeFromDoc(doc, includeCommunity: true);
  }

  Future<ExploreCreatorDetail> getCreatorDetail(String creatorUid) async {
    if (creatorUid.trim().isEmpty) {
      throw StateError('Creator not found');
    }

    final creator = await _getCreator(creatorUid);
    final userDoc = await firestore.collection('users').doc(creatorUid).get();
    final userData = userDoc.data() ?? {};
    final recipes = await _getCreatorRecipes(creatorUid);
    final followingSnapshot = await firestore
        .collection('users')
        .doc(creatorUid)
        .collection('followingCreators')
        .get();

    return ExploreCreatorDetail(
      summary: ExploreCreatorSummary(
        uid: creatorUid,
        name: creator.name,
        avatarPath: creator.profileImage,
        followerCount: _intValue(userData['followerCount']),
        isFollowing: await _isFollowingCreator(creatorUid),
      ),
      bio: _stringValue(
        userData['bio'],
        fallback: 'Hi, I am ${creator.name}, a recipe developer.',
      ),
      postCount: recipes.length,
      followingCount: followingSnapshot.docs.length,
      isFollowing: await _isFollowingCreator(creatorUid),
      recipes: recipes,
    );
  }

  Future<List<ExploreRecipeModel>> _getCreatorRecipes(String creatorUid) async {
    var snapshot = await firestore
        .collection('recipes')
        .where('creatorId', isEqualTo: creatorUid)
        .get();
    if (snapshot.docs.isEmpty) {
      snapshot = await firestore
          .collection('recipes')
          .where('creatorUid', isEqualTo: creatorUid)
          .get();
    }

    final docs =
        snapshot.docs.where((doc) {
          return _isPublicFinalizedRecipe(doc.data());
        }).toList()..sort((first, second) {
          final firstData = first.data();
          final secondData = second.data();
          final firstDate = _dateTime(
            firstData['updatedAt'] ?? firstData['createdAt'],
          );
          final secondDate = _dateTime(
            secondData['updatedAt'] ?? secondData['createdAt'],
          );
          return secondDate.compareTo(firstDate);
        });

    final recipes = <ExploreRecipeModel>[];
    for (final doc in docs) {
      recipes.add(await _recipeFromDoc(doc, includeCommunity: false));
    }
    return recipes;
  }

  Future<ExploreRecipeModel> _recipeFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required bool includeCommunity,
  }) async {
    final data = doc.data() ?? {};
    final creatorUid = _stringValue(data['creatorId']).isNotEmpty
        ? _stringValue(data['creatorId'])
        : _stringValue(data['creatorUid']);
    final currentUid = auth.currentUser?.uid ?? '';
    final isCurrentUserCreator =
        creatorUid.isNotEmpty && creatorUid == currentUid;
    final isFollowingAuthor = await _isFollowingCreator(creatorUid);
    final isFavourite = await _isFavouriteRecipe(doc.id);
    final creator = await _getCreator(creatorUid);
    final categoryIds = _stringList(data['categoryIds']);
    final customCategoryIds = _stringList(data['customCategoryIds']);
    final categoryNames = await _resolveOptionNames(
      configId: 'recipe_categories',
      ids: categoryIds,
      customCollectionId: 'custom_categories',
      customIds: customCategoryIds,
    );
    final allergenNames = await _resolveOptionNames(
      configId: 'allergies',
      ids: _stringList(data['allergenIds']),
      customCollectionId: 'custom_allergens',
      customIds: _stringList(data['customAllergenIds']),
    );
    final media = _stringList(data['media']);
    final nutrition = _nutritionFromData(data['totalNutrients']);
    final ingredients = includeCommunity
        ? await _getIngredients(
            doc.reference,
            totalCalories: nutrition.calories,
          )
        : const <ExploreIngredient>[];
    final ingredientNames = includeCommunity
        ? ingredients.map((ingredient) => ingredient.name).toList()
        : await _getIngredientSearchNames(doc.reference);
    final instructions = includeCommunity
        ? await _getInstructionSections(doc.reference)
        : const <ExploreInstructionSection>[];
    final community = includeCommunity
        ? await _getCommunity(doc.reference, creator.name)
        : const ExploreCommunity(
            authorBio: '',
            ratingBreakdown: [],
            reviews: [],
            comments: [],
          );
    final relatedRecipes = includeCommunity
        ? await _getRelatedRecipes(
            creatorUid: creatorUid,
            currentRecipeId: doc.id,
          )
        : const <ExploreRecipeSummary>[];
    final hasRatedByCurrentUser = includeCommunity && currentUid.isNotEmpty
        ? (await doc.reference.collection('ratings').doc(currentUid).get())
              .exists
        : false;
    final ratingCount = _intValue(data['ratingCount']);
    final publishedAt = _dateTime(data['updatedAt'] ?? data['createdAt']);

    return ExploreRecipeModel(
      id: doc.id,
      creatorUid: creatorUid,
      title: _stringValue(data['name'], fallback: 'Untitled Recipe'),
      author: isCurrentUserCreator ? 'You' : creator.name,
      publishedAtLabel: _dateLabel(publishedAt),
      authorAvatarPath: creator.profileImage,
      authorFollowerCount: creator.followerCount,
      imagePath: media.isNotEmpty
          ? media.first
          : 'assets/images/empty_page.png',
      imagePaths: media,
      description: _stringValue(data['description']),
      otherNames: _stringList(data['otherNames']),
      category: categoryNames.isEmpty
          ? 'Uncategorised'
          : categoryNames.join(', '),
      categoryIds: categoryIds,
      customCategoryIds: customCategoryIds,
      tags: _stringList(data['tags']),
      ingredientNames: ingredientNames,
      allergenInfo: allergenNames.isEmpty
          ? 'No allergens listed'
          : allergenNames.join(', '),
      totalTime: '${_intValue(data['preparationTime'])} min',
      difficulty: _difficultyLabel(data['difficultyLevel']),
      servings: _intValue(data['servings']).clamp(1, 999),
      rating: _doubleValue(data['averageRating']),
      ratingCount: ratingCount,
      commentCount: _intValue(data['commentCount']),
      totalViews: _intValue(data['totalViews']),
      publishedAt: publishedAt,
      isFollowingAuthor: isFollowingAuthor,
      isFavourite: isFavourite,
      isCreatedByCurrentUser: isCurrentUserCreator,
      hasRatedByCurrentUser: hasRatedByCurrentUser,
      ingredients: ingredients,
      instructionSections: instructions,
      nutrition: nutrition,
      community: community,
      relatedRecipes: relatedRecipes,
    );
  }

  Future<List<String>> _getIngredientSearchNames(
    DocumentReference<Map<String, dynamic>> recipe,
  ) async {
    final snapshot = await recipe.collection('ingredients').get();
    return snapshot.docs
        .map((doc) => _stringValue(doc.data()['name']))
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
  }

  ExploreNutrition _nutritionFromData(dynamic value) {
    final nutrients = value is Map ? value : const {};
    return ExploreNutrition(
      calories: _numericValue(nutrients['calories'])?.round() ?? 0,
      carbsGrams: _numericValue(nutrients['carbohydrates'])?.round() ?? 0,
      proteinGrams: _numericValue(nutrients['protein'])?.round() ?? 0,
      fatGrams: _numericValue(nutrients['fat'])?.round() ?? 0,
    );
  }

  Future<List<ExploreRecipeSummary>> _getRelatedRecipes({
    required String creatorUid,
    required String currentRecipeId,
  }) async {
    if (creatorUid.isEmpty) return const [];

    var snapshot = await firestore
        .collection('recipes')
        .where('creatorId', isEqualTo: creatorUid)
        .get();
    if (snapshot.docs.isEmpty) {
      snapshot = await firestore
          .collection('recipes')
          .where('creatorUid', isEqualTo: creatorUid)
          .get();
    }

    final docs =
        snapshot.docs.where((doc) {
          final data = doc.data();
          return doc.id != currentRecipeId && _isPublicFinalizedRecipe(data);
        }).toList()..sort((first, second) {
          final firstData = first.data();
          final secondData = second.data();
          final firstDate = _dateTime(
            firstData['updatedAt'] ?? firstData['createdAt'],
          );
          final secondDate = _dateTime(
            secondData['updatedAt'] ?? secondData['createdAt'],
          );
          return secondDate.compareTo(firstDate);
        });

    return docs.take(4).map((doc) {
      final data = doc.data();
      final media = _stringList(data['media']);
      return ExploreRecipeSummary(
        id: doc.id,
        title: _stringValue(data['name'], fallback: 'Untitled Recipe'),
        imagePath: media.isNotEmpty
            ? media.first
            : 'assets/images/empty_page.png',
      );
    }).toList();
  }

  Future<_CreatorProfile> _getCreator(String creatorUid) async {
    if (creatorUid.isEmpty) {
      return const _CreatorProfile(name: 'Unknown Creator', profileImage: '');
    }

    final doc = await firestore.collection('users').doc(creatorUid).get();
    final data = doc.data() ?? {};
    return _CreatorProfile(
      name: _stringValue(data['name'], fallback: 'Unknown Creator'),
      profileImage: _stringValue(data['profileImage']),
      followerCount: _intValue(data['followerCount']),
    );
  }

  Future<bool> _isFollowingCreator(String creatorUid) async {
    final uid = auth.currentUser?.uid ?? '';
    if (uid.isEmpty || creatorUid.isEmpty || uid == creatorUid) return false;
    final doc = await firestore
        .collection('users')
        .doc(uid)
        .collection('followingCreators')
        .doc(creatorUid)
        .get();
    return doc.exists;
  }

  Future<bool> _isFavouriteRecipe(String recipeId) async {
    final uid = auth.currentUser?.uid ?? '';
    if (uid.isEmpty || recipeId.isEmpty) return false;
    final doc = await firestore
        .collection('users')
        .doc(uid)
        .collection('saved_recipes')
        .doc(recipeId)
        .get();
    return doc.exists;
  }

  Future<List<String>> _resolveOptionNames({
    required String configId,
    required List<String> ids,
    required String customCollectionId,
    required List<String> customIds,
  }) async {
    final names = <String>[];

    for (final id in ids) {
      final doc = await firestore
          .collection('app_config')
          .doc(configId)
          .collection('items')
          .doc(id)
          .get();
      names.add(_stringValue(doc.data()?['name'], fallback: id));
    }

    for (final id in customIds) {
      final doc = await firestore
          .collection('custom')
          .doc(customCollectionId)
          .collection('items')
          .doc(id)
          .get();
      names.add(_stringValue(doc.data()?['name'], fallback: id));
    }

    return names.where((name) => name.trim().isNotEmpty).toList();
  }

  Future<List<ExploreIngredient>> _getIngredients(
    DocumentReference<Map<String, dynamic>> recipe, {
    required int totalCalories,
  }) async {
    final snapshot = await recipe.collection('ingredients').get();
    final categoryIds = snapshot.docs
        .map((doc) => _stringValue(doc.data()['ingredient_categories_id']))
        .where((id) => id.isNotEmpty)
        .toSet();
    final categoryNames = await _resolveIngredientCategoryNames(categoryIds);

    return Future.wait(
      snapshot.docs.map((doc) async {
        final data = doc.data();
        final amount = _doubleValue(data['amount']);
        final categoryId = _stringValue(data['ingredient_categories_id']);
        final nutrients = _nutritionFromData(data['nutrients']);
        final calories = nutrients.calories.toDouble();
        final unit = await _resolveIngredientUnitName(
          customUnitId: _stringValue(data['customUnitId']),
          unitId: _stringValue(data['unitId']),
        );

        return ExploreIngredient(
          name: _stringValue(data['name'], fallback: 'Ingredient'),
          amount: '${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 1)} $unit'
              .trim(),
          calories: _caloriesLabel(calories),
          imagePath: _stringValue(data['image'], fallback: ''),
          nutritionPercent: totalCalories <= 0
              ? 0
              : (calories / totalCalories).clamp(0.0, 1.0),
          caloriesValue: calories,
          carbsGrams: nutrients.carbsGrams.toDouble(),
          proteinGrams: nutrients.proteinGrams.toDouble(),
          fatGrams: nutrients.fatGrams.toDouble(),
          ingredientCategoryId: categoryId,
          ingredientCategoryName: categoryNames[categoryId] ?? '',
        );
      }).toList(),
    );
  }

  Future<Map<String, String>> _resolveIngredientCategoryNames(
    Set<String> categoryIds,
  ) async {
    if (categoryIds.isEmpty) return const {};

    final entries = await Future.wait(
      categoryIds.map((id) async {
        final doc = await firestore
            .collection('app_config')
            .doc('ingredient_categories')
            .collection('items')
            .doc(id)
            .get();
        return MapEntry(id, _stringValue(doc.data()?['name'], fallback: id));
      }),
    );

    return Map.fromEntries(entries);
  }

  String _caloriesLabel(double calories) {
    if (calories <= 0) return '';
    return '${_formatNumber(calories)} kcal';
  }

  double? _numericValue(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is Map) return _numericValue(value['value'] ?? value['amount']);
    return double.tryParse(value?.toString() ?? '');
  }

  String _formatNumber(double value) {
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.05) return rounded.toInt().toString();
    return value.toStringAsFixed(1);
  }

  Future<String> _resolveIngredientUnitName({
    required String customUnitId,
    required String unitId,
  }) async {
    if (customUnitId.isNotEmpty) {
      final doc = await firestore
          .collection('custom')
          .doc('custom_units')
          .collection('items')
          .doc(customUnitId)
          .get();
      return _stringValue(doc.data()?['name'], fallback: customUnitId);
    }

    if (unitId.isNotEmpty) {
      final doc = await firestore
          .collection('app_config')
          .doc('ingredient_units')
          .collection('items')
          .doc(unitId)
          .get();
      return _stringValue(doc.data()?['name'], fallback: unitId);
    }

    return '';
  }

  Future<List<ExploreInstructionSection>> _getInstructionSections(
    DocumentReference<Map<String, dynamic>> recipe,
  ) async {
    final snapshot = await recipe.collection('instructions').get();
    final steps = snapshot.docs.map((doc) => doc.data()).toList()
      ..sort((first, second) {
        final sectionCompare = _intValue(
          first['sectionIndex'],
        ).compareTo(_intValue(second['sectionIndex']));
        if (sectionCompare != 0) return sectionCompare;
        return _intValue(
          first['stepIndex'],
        ).compareTo(_intValue(second['stepIndex']));
      });

    if (steps.isEmpty) return const [];

    final sections = <String, List<Map<String, dynamic>>>{};
    for (final step in steps) {
      final title = _stringValue(
        step['sectionTitle'],
        fallback: 'Instructions',
      );
      sections.putIfAbsent(title, () => []).add(step);
    }

    return sections.entries.map((entry) {
      return ExploreInstructionSection(
        title: entry.key,
        steps: entry.value.map((step) {
          return ExploreInstructionStep(
            title: 'Step ${_intValue(step['stepIndex'])}',
            description: _stringValue(step['description']),
            imagePath: _stringValue(step['stepImage'], fallback: ''),
          );
        }).toList(),
      );
    }).toList();
  }

  Future<ExploreCommunity> _getCommunity(
    DocumentReference<Map<String, dynamic>> recipe,
    String fallbackAuthor,
  ) async {
    final ratingsSnapshot = await recipe
        .collection('ratings')
        .orderBy('createdAt', descending: true)
        .get();
    final commentsSnapshot = await recipe
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .get();
    final ratings = <ExploreReview>[];
    final breakdown = {for (var star = 1; star <= 5; star++) star: 0};

    for (final doc in ratingsSnapshot.docs) {
      final data = doc.data();
      final rating = _doubleValue(data['rating']);
      final roundedRating = rating.round().clamp(1, 5);
      breakdown[roundedRating] = (breakdown[roundedRating] ?? 0) + 1;
      final creator = await _getCreator(_stringValue(data['userId']));
      final createdAt = _dateTime(data['createdAt']);
      ratings.add(
        ExploreReview(
          author: creator.name,
          avatarPath: creator.profileImage,
          timeAgo: _dateLabel(createdAt),
          createdAt: createdAt,
          rating: rating,
        ),
      );
    }

    final comments = <ExploreComment>[];
    for (final doc in commentsSnapshot.docs) {
      comments.add(await _commentFromDoc(doc));
    }

    return ExploreCommunity(
      authorBio: 'Recipe shared by $fallbackAuthor.',
      ratingBreakdown: List.generate(5, (index) {
        final stars = 5 - index;
        return ExploreRatingBreakdown(
          stars: stars,
          count: breakdown[stars] ?? 0,
        );
      }),
      reviews: ratings,
      comments: comments,
    );
  }

  Future<ExploreComment> _commentFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final creator = await _getCreator(_stringValue(data['userId']));
    final createdAt = _dateTime(data['createdAt']);
    final uid = auth.currentUser?.uid ?? '';
    final isLiked = uid.isNotEmpty
        ? (await doc.reference.collection('likedBy').doc(uid).get()).exists
        : false;
    final repliesSnapshot = await doc.reference
        .collection('replies')
        .orderBy('createdAt', descending: false)
        .get();
    final replies = <ExploreCommentReply>[];
    for (final replyDoc in repliesSnapshot.docs) {
      replies.add(await _replyFromDoc(replyDoc));
    }

    return ExploreComment(
      id: doc.id,
      author: creator.name,
      avatarPath: creator.profileImage,
      timeAgo: _dateLabel(createdAt),
      createdAt: createdAt,
      content: _stringValue(data['content']),
      likes: _intValue(data['likes']),
      isLiked: isLiked,
      replies: replies,
    );
  }

  Future<ExploreCommentReply> _replyFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();
    final creator = await _getCreator(_stringValue(data['userId']));
    final createdAt = _dateTime(data['createdAt']);
    final uid = auth.currentUser?.uid ?? '';
    final isLiked = uid.isNotEmpty
        ? (await doc.reference.collection('likedBy').doc(uid).get()).exists
        : false;
    final nestedSnapshot = await doc.reference
        .collection('replies')
        .orderBy('createdAt', descending: false)
        .get();
    final replies = <ExploreCommentReply>[];
    for (final nestedDoc in nestedSnapshot.docs) {
      replies.add(await _replyFromDoc(nestedDoc));
    }
    return ExploreCommentReply(
      id: doc.id,
      documentPath: doc.reference.path,
      author: creator.name,
      avatarPath: creator.profileImage,
      timeAgo: _dateLabel(createdAt),
      createdAt: createdAt,
      content: _stringValue(data['content']),
      likes: _intValue(data['likes']),
      isLiked: isLiked,
      replies: replies,
    );
  }

  Future<void> submitRating({
    required String recipeId,
    required double rating,
  }) async {
    final uid = _requiredUid();
    final recipeRef = firestore.collection('recipes').doc(recipeId);
    final ratingRef = recipeRef.collection('ratings').doc(uid);
    String ownerUid = '';
    String recipeTitle = 'your recipe';
    var isNewRating = false;

    await firestore.runTransaction((transaction) async {
      final recipeSnapshot = await transaction.get(recipeRef);
      if (!recipeSnapshot.exists) {
        throw StateError('Recipe not found');
      }

      final ratingSnapshot = await transaction.get(ratingRef);
      final recipeData = recipeSnapshot.data() ?? {};
      ownerUid = _recipeCreatorUid(recipeData);
      recipeTitle = _stringValue(recipeData['name'], fallback: 'your recipe');
      final currentCount = _intValue(recipeData['ratingCount']);
      final currentAverage = _doubleValue(recipeData['averageRating']);
      final currentTotal = currentAverage * currentCount;

      final hasExistingRating = ratingSnapshot.exists;
      isNewRating = !hasExistingRating;
      final ratingData = ratingSnapshot.data();
      final oldRating = hasExistingRating && ratingData != null
          ? _doubleValue(ratingData['rating'])
          : 0.0;
      final nextCount = hasExistingRating ? currentCount : currentCount + 1;
      final nextTotal = hasExistingRating
          ? currentTotal - oldRating + rating
          : currentTotal + rating;
      final nextAverage = nextCount == 0 ? 0.0 : nextTotal / nextCount;
      final createdAt = hasExistingRating && ratingData != null
          ? ratingData['createdAt']
          : FieldValue.serverTimestamp();

      transaction.set(ratingRef, {
        'userId': uid,
        'rating': rating,
        'createdAt': createdAt,
      }, SetOptions(merge: true));
      transaction.update(recipeRef, {
        'averageRating': nextAverage,
        'ratingCount': nextCount,
      });
    });

    if (isNewRating) {
      await _notifyUser(
        receiverUid: ownerUid,
        type: 'newRating',
        title: 'New Rating',
        message:
            '${await _currentUserName()} rated $recipeTitle ${rating.toStringAsFixed(1)} stars.',
      );
    }
  }

  Future<void> addComment({
    required String recipeId,
    required String content,
  }) async {
    final uid = _requiredUid();
    final recipeRef = firestore.collection('recipes').doc(recipeId);
    final commentRef = recipeRef.collection('comments').doc();
    String ownerUid = '';
    String recipeTitle = 'your recipe';

    await firestore.runTransaction((transaction) async {
      final recipeSnapshot = await transaction.get(recipeRef);
      if (!recipeSnapshot.exists) {
        throw StateError('Recipe not found');
      }
      final recipeData = recipeSnapshot.data() ?? {};
      ownerUid = _recipeCreatorUid(recipeData);
      recipeTitle = _stringValue(recipeData['name'], fallback: 'your recipe');

      transaction.set(commentRef, {
        'userId': uid,
        'content': content.trim(),
        'likes': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(recipeRef, {'commentCount': FieldValue.increment(1)});
    });

    await _notifyUser(
      receiverUid: ownerUid,
      type: 'newComment',
      title: 'New Comment',
      message:
          '${await _currentUserName()} commented on $recipeTitle: ${_shortText(content)}',
    );
  }

  Future<void> incrementViewCount(String recipeId) async {
    final recipeRef = firestore.collection('recipes').doc(recipeId);
    await recipeRef.update({'totalViews': FieldValue.increment(1)});
  }

  Future<void> toggleCommentLike({
    required String recipeId,
    required String commentId,
  }) async {
    final uid = _requiredUid();
    final commentRef = firestore
        .collection('recipes')
        .doc(recipeId)
        .collection('comments')
        .doc(commentId);
    final likeRef = commentRef.collection('likedBy').doc(uid);
    var isNewLike = false;
    var commentOwnerUid = '';
    var recipeTitle = 'your comment';

    await firestore.runTransaction((transaction) async {
      final commentSnapshot = await transaction.get(commentRef);
      if (!commentSnapshot.exists) {
        throw StateError('Comment not found');
      }
      final recipeSnapshot = await transaction.get(
        firestore.collection('recipes').doc(recipeId),
      );
      commentOwnerUid = _stringValue(commentSnapshot.data()?['userId']);
      recipeTitle = _stringValue(
        recipeSnapshot.data()?['name'],
        fallback: 'your comment',
      );
      final likeSnapshot = await transaction.get(likeRef);
      if (likeSnapshot.exists) {
        transaction.delete(likeRef);
        transaction.update(commentRef, {'likes': FieldValue.increment(-1)});
      } else {
        isNewLike = true;
        transaction.set(likeRef, {
          'userId': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(commentRef, {'likes': FieldValue.increment(1)});
      }
    });

    if (isNewLike) {
      await _notifyUser(
        receiverUid: commentOwnerUid,
        type: 'newLike',
        title: 'New Like',
        message:
            '${await _currentUserName()} liked your comment on $recipeTitle.',
      );
    }
  }

  Future<void> addCommentReply({
    required String recipeId,
    required String commentId,
    required String content,
  }) async {
    final uid = _requiredUid();
    final commentRef = firestore
        .collection('recipes')
        .doc(recipeId)
        .collection('comments')
        .doc(commentId);
    final replyRef = commentRef.collection('replies').doc();
    String commentOwnerUid = '';
    String recipeTitle = 'your recipe';

    await firestore.runTransaction((transaction) async {
      final commentSnapshot = await transaction.get(commentRef);
      if (!commentSnapshot.exists) {
        throw StateError('Comment not found');
      }
      final recipeSnapshot = await transaction.get(
        firestore.collection('recipes').doc(recipeId),
      );
      commentOwnerUid = _stringValue(commentSnapshot.data()?['userId']);
      recipeTitle = _stringValue(
        recipeSnapshot.data()?['name'],
        fallback: 'your recipe',
      );
      transaction.set(replyRef, {
        'userId': uid,
        'content': content.trim(),
        'likes': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(commentRef, {'replyCount': FieldValue.increment(1)});
    });

    await _notifyUser(
      receiverUid: commentOwnerUid,
      type: 'newReply',
      title: 'New Reply',
      message:
          '${await _currentUserName()} replied on $recipeTitle: ${_shortText(content)}',
    );
  }

  Future<void> toggleReplyLike({required String replyPath}) async {
    final uid = _requiredUid();
    final replyRef = firestore.doc(replyPath);
    final likeRef = replyRef.collection('likedBy').doc(uid);
    var isNewLike = false;
    var replyOwnerUid = '';
    var recipeTitle = 'your reply';

    await firestore.runTransaction((transaction) async {
      final replySnapshot = await transaction.get(replyRef);
      if (!replySnapshot.exists) {
        throw StateError('Reply not found');
      }
      replyOwnerUid = _stringValue(replySnapshot.data()?['userId']);
      recipeTitle = await _recipeTitleFromReplyPath(replyPath);
      final likeSnapshot = await transaction.get(likeRef);
      if (likeSnapshot.exists) {
        transaction.delete(likeRef);
        transaction.update(replyRef, {'likes': FieldValue.increment(-1)});
      } else {
        isNewLike = true;
        transaction.set(likeRef, {
          'userId': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(replyRef, {'likes': FieldValue.increment(1)});
      }
    });

    if (isNewLike) {
      await _notifyUser(
        receiverUid: replyOwnerUid,
        type: 'newLike',
        title: 'New Like',
        message:
            '${await _currentUserName()} liked your reply on $recipeTitle.',
      );
    }
  }

  Future<void> addReplyToReply({
    required String replyPath,
    required String content,
  }) async {
    final uid = _requiredUid();
    final replyRef = firestore.doc(replyPath);
    final nestedReplyRef = replyRef.collection('replies').doc();
    String replyOwnerUid = '';
    String recipeTitle = 'your comment';

    await firestore.runTransaction((transaction) async {
      final replySnapshot = await transaction.get(replyRef);
      if (!replySnapshot.exists) {
        throw StateError('Reply not found');
      }
      replyOwnerUid = _stringValue(replySnapshot.data()?['userId']);
      recipeTitle = await _recipeTitleFromReplyPath(replyPath);
      transaction.set(nestedReplyRef, {
        'userId': uid,
        'content': content.trim(),
        'likes': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(replyRef, {'replyCount': FieldValue.increment(1)});
    });

    await _notifyUser(
      receiverUid: replyOwnerUid,
      type: 'newReply',
      title: 'New Reply',
      message:
          '${await _currentUserName()} replied on $recipeTitle: ${_shortText(content)}',
    );
  }

  Future<void> toggleCreatorFollow({
    required String creatorUid,
    required bool follow,
  }) async {
    final uid = _requiredUid();
    if (uid == creatorUid) {
      throw StateError('You cannot follow yourself.');
    }
    final followRef = firestore
        .collection('users')
        .doc(uid)
        .collection('followingCreators')
        .doc(creatorUid);
    final creatorRef = firestore.collection('users').doc(creatorUid);
    await firestore.runTransaction((transaction) async {
      final followSnapshot = await transaction.get(followRef);
      if (follow && !followSnapshot.exists) {
        transaction.set(followRef, {
          'creatorUid': creatorUid,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        transaction.set(creatorRef, {
          'followerCount': FieldValue.increment(1),
        }, SetOptions(merge: true));
      } else if (!follow && followSnapshot.exists) {
        transaction.delete(followRef);
        transaction.set(creatorRef, {
          'followerCount': FieldValue.increment(-1),
        }, SetOptions(merge: true));
      }
    });

    if (follow) {
      await _notifyUser(
        receiverUid: creatorUid,
        type: 'newFollower',
        title: 'New Follower',
        message: '${await _currentUserName()} follows you.',
      );
    }
  }

  Future<void> updateRecipeVisibility({
    required String recipeId,
    required bool isPublished,
  }) async {
    final uid = _requiredUid();
    final recipeRef = firestore.collection('recipes').doc(recipeId);
    var shouldNotifyFollowers = false;
    var recipeTitle = 'a new recipe';

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(recipeRef);
      if (!snapshot.exists) {
        throw StateError('Recipe not found');
      }

      final data = snapshot.data() ?? {};
      shouldNotifyFollowers =
          isPublished &&
          _stringValue(data['visibility']) != 'public' &&
          data['isFinalized'] != false;
      recipeTitle = _stringValue(data['name'], fallback: 'a new recipe');
      final creatorUid = _stringValue(data['creatorId']).isNotEmpty
          ? _stringValue(data['creatorId'])
          : _stringValue(data['creatorUid']);
      if (creatorUid != uid) {
        throw StateError('Only the recipe creator can change visibility.');
      }

      transaction.update(recipeRef, {
        'visibility': isPublished ? 'public' : 'private',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    if (shouldNotifyFollowers) {
      await _notifyFollowersOfNewRecipe(
        recipeOwnerUid: uid,
        recipeTitle: recipeTitle,
      );
      await recipeRef.update({
        'publicNotificationSentAt': FieldValue.serverTimestamp(),
      });
    }
  }

  String _requiredUid() {
    final uid = auth.currentUser?.uid ?? '';
    if (uid.isEmpty) {
      throw FirebaseAuthException(
        code: 'not-authenticated',
        message: 'User is not authenticated.',
      );
    }
    return uid;
  }

  Future<void> _notifyUser({
    required String receiverUid,
    required String type,
    required String title,
    required String message,
  }) async {
    final senderUid = auth.currentUser?.uid ?? '';
    if (receiverUid.isEmpty || senderUid.isEmpty || receiverUid == senderUid) {
      return;
    }

    try {
      final notificationRef = await firestore
          .collection('users')
          .doc(receiverUid)
          .collection('notifications')
          .add({
            'type': type,
            'title': title,
            'message': message,
            'isRead': false,
            'senderUid': senderUid,
            'createdAt': FieldValue.serverTimestamp(),
          });
      if (!await _isNotificationEnabled(receiverUid: receiverUid, type: type)) {
        return;
      }

      await _sendPushToUser(
        receiverUid: receiverUid,
        title: title,
        message: message,
        data: {
          'type': type,
          'notificationId': notificationRef.id,
          'senderUid': senderUid,
        },
      );
    } on FirebaseException {
      // Notification writes are best-effort; the original action already
      // succeeded and should not be rolled back by notification rules.
    }
  }

  Future<bool> _isNotificationEnabled({
    required String receiverUid,
    required String type,
  }) async {
    final preferenceId = _preferenceIdForNotificationType(type);
    if (preferenceId == null) return true;

    final preferenceDoc = await firestore
        .collection('users')
        .doc(receiverUid)
        .collection('notification_preferences')
        .doc(preferenceId)
        .get();
    final enabled = preferenceDoc.data()?['enabled'];
    return enabled is bool ? enabled : true;
  }

  String? _preferenceIdForNotificationType(String type) {
    switch (type) {
      case 'newFollower':
        return 'new_follower_notification';
      case 'newRating':
        return 'new_rating_notification';
      case 'newComment':
        return 'new_comment_notification';
      case 'newRecipe':
        return 'new_recipe_notification';
      case 'newReply':
        return 'new_reply_notification';
      case 'newLike':
        return 'new_like_notification';
      default:
        return null;
    }
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
      // Push sending is best-effort; the Firestore notification is the source
      // of truth for the notification list.
    }
  }

  Future<String> _currentUserName() async {
    final uid = auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return 'Someone';
    final doc = await firestore.collection('users').doc(uid).get();
    return _stringValue(doc.data()?['name'], fallback: 'Someone');
  }

  String _recipeCreatorUid(Map<String, dynamic> data) {
    final creatorId = _stringValue(data['creatorId']);
    if (creatorId.isNotEmpty) return creatorId;
    return _stringValue(data['creatorUid']);
  }

  bool _isPublicFinalizedRecipe(Map<String, dynamic> data) {
    return _stringValue(data['visibility']) == 'public' &&
        data['isFinalized'] != false;
  }

  String _shortText(String value) {
    final text = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.length <= 70) return text;
    return '${text.substring(0, 67)}...';
  }

  Future<String> _recipeTitleFromReplyPath(String replyPath) async {
    final parts = replyPath.split('/');
    final recipeIndex = parts.indexOf('recipes');
    if (recipeIndex < 0 || recipeIndex + 1 >= parts.length) {
      return 'your comment';
    }
    final recipeId = parts[recipeIndex + 1];
    final doc = await firestore.collection('recipes').doc(recipeId).get();
    return _stringValue(doc.data()?['name'], fallback: 'your comment');
  }

  Future<void> _notifyFollowersOfNewRecipe({
    required String recipeOwnerUid,
    required String recipeTitle,
  }) async {
    if (recipeOwnerUid.isEmpty) return;
    try {
      final creatorName = await _currentUserName();
      final followerUids = await _getFollowerUids(recipeOwnerUid);

      for (final followerUid in followerUids) {
        await _notifyUser(
          receiverUid: followerUid,
          type: 'newRecipe',
          title: 'New Recipe',
          message: '$creatorName posted $recipeTitle.',
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

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} min ago';
    if (difference.inDays < 1) return '${difference.inHours} hrs ago';
    if (difference.inDays == 1) return 'Yesterday';
    return '${date.day}/${date.month}/${date.year}';
  }

  DateTime _dateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _difficultyLabel(Object? value) {
    final level = _intValue(value);
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
        return 'Not set';
    }
  }

  static String _stringValue(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static List<String> _stringList(Object? value) {
    if (value is Iterable) {
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static int _intValue(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _doubleValue(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class _CreatorProfile {
  final String name;
  final String profileImage;
  final int followerCount;

  const _CreatorProfile({
    required this.name,
    required this.profileImage,
    this.followerCount = 0,
  });
}
