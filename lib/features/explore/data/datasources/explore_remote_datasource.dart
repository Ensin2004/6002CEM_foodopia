import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
          return _stringValue(doc.data()['visibility']) == 'public';
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
    final ingredients = includeCommunity
        ? await _getIngredients(doc.reference)
        : const <ExploreIngredient>[];
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
      allergenInfo: allergenNames.isEmpty
          ? 'No allergens listed'
          : allergenNames.join(', '),
      totalTime: '${_intValue(data['preparationTime'])} min',
      difficulty: _difficultyLabel(data['difficultyLevel']),
      rating: _doubleValue(data['averageRating']),
      ratingCount: ratingCount,
      commentCount: _intValue(data['commentCount']),
      totalViews: _intValue(data['totalViews']),
      publishedAt: publishedAt,
      isFollowingAuthor: isFollowingAuthor,
      isFavourite: isFavourite,
      isCreatedByCurrentUser: isCurrentUserCreator,
      ingredients: ingredients,
      instructionSections: instructions,
      nutrition: const ExploreNutrition(
        calories: 0,
        carbsGrams: 0,
        proteinGrams: 0,
        fatGrams: 0,
      ),
      community: community,
      relatedRecipes: relatedRecipes,
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
          return doc.id != currentRecipeId &&
              _stringValue(data['visibility']) == 'public';
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
      return const _CreatorProfile(
        name: 'Unknown Creator',
        profileImage: 'assets/images/onboarding1.png',
      );
    }

    final doc = await firestore.collection('users').doc(creatorUid).get();
    final data = doc.data() ?? {};
    return _CreatorProfile(
      name: _firstNotBlank([
        data['name']?.toString(),
        data['displayName']?.toString(),
        'Unknown Creator',
      ]),
      profileImage: _firstNotBlank([
        data['profileImage']?.toString(),
        data['profileImageUrl']?.toString(),
        data['photoUrl']?.toString(),
        data['photoURL']?.toString(),
        'assets/images/onboarding1.png',
      ]),
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
    DocumentReference<Map<String, dynamic>> recipe,
  ) async {
    final snapshot = await recipe.collection('ingredients').get();

    return Future.wait(
      snapshot.docs.map((doc) async {
        final data = doc.data();
        final amount = _doubleValue(data['amount']);
        final unit = await _resolveIngredientUnitName(
          customUnitId: _stringValue(data['customUnitId']),
          unitId: _stringValue(data['unitId']),
        );

        return ExploreIngredient(
          name: _stringValue(data['name'], fallback: 'Ingredient'),
          amount: '${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 1)} $unit'
              .trim(),
          calories: '',
          imagePath: _stringValue(
            data['image'],
            fallback: 'assets/images/meal1.png',
          ),
          nutritionPercent: 0,
        );
      }).toList(),
    );
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
            imagePath: _stringValue(
              step['stepImage'],
              fallback: 'assets/images/meal3(2).png',
            ),
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

    await firestore.runTransaction((transaction) async {
      final recipeSnapshot = await transaction.get(recipeRef);
      if (!recipeSnapshot.exists) {
        throw StateError('Recipe not found');
      }

      final ratingSnapshot = await transaction.get(ratingRef);
      final recipeData = recipeSnapshot.data() ?? {};
      final currentCount = _intValue(recipeData['ratingCount']);
      final currentAverage = _doubleValue(recipeData['averageRating']);
      final currentTotal = currentAverage * currentCount;

      final hasExistingRating = ratingSnapshot.exists;
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
  }

  Future<void> addComment({
    required String recipeId,
    required String content,
  }) async {
    final uid = _requiredUid();
    final recipeRef = firestore.collection('recipes').doc(recipeId);
    final commentRef = recipeRef.collection('comments').doc();

    await firestore.runTransaction((transaction) async {
      final recipeSnapshot = await transaction.get(recipeRef);
      if (!recipeSnapshot.exists) {
        throw StateError('Recipe not found');
      }

      transaction.set(commentRef, {
        'userId': uid,
        'content': content.trim(),
        'likes': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(recipeRef, {'commentCount': FieldValue.increment(1)});
    });
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

    await firestore.runTransaction((transaction) async {
      final commentSnapshot = await transaction.get(commentRef);
      if (!commentSnapshot.exists) {
        throw StateError('Comment not found');
      }
      final likeSnapshot = await transaction.get(likeRef);
      if (likeSnapshot.exists) {
        transaction.delete(likeRef);
        transaction.update(commentRef, {'likes': FieldValue.increment(-1)});
      } else {
        transaction.set(likeRef, {
          'userId': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(commentRef, {'likes': FieldValue.increment(1)});
      }
    });
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

    await firestore.runTransaction((transaction) async {
      final commentSnapshot = await transaction.get(commentRef);
      if (!commentSnapshot.exists) {
        throw StateError('Comment not found');
      }
      transaction.set(replyRef, {
        'userId': uid,
        'content': content.trim(),
        'likes': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(commentRef, {'replyCount': FieldValue.increment(1)});
    });
  }

  Future<void> toggleReplyLike({required String replyPath}) async {
    final uid = _requiredUid();
    final replyRef = firestore.doc(replyPath);
    final likeRef = replyRef.collection('likedBy').doc(uid);

    await firestore.runTransaction((transaction) async {
      final replySnapshot = await transaction.get(replyRef);
      if (!replySnapshot.exists) {
        throw StateError('Reply not found');
      }
      final likeSnapshot = await transaction.get(likeRef);
      if (likeSnapshot.exists) {
        transaction.delete(likeRef);
        transaction.update(replyRef, {'likes': FieldValue.increment(-1)});
      } else {
        transaction.set(likeRef, {
          'userId': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(replyRef, {'likes': FieldValue.increment(1)});
      }
    });
  }

  Future<void> addReplyToReply({
    required String replyPath,
    required String content,
  }) async {
    final uid = _requiredUid();
    final replyRef = firestore.doc(replyPath);
    final nestedReplyRef = replyRef.collection('replies').doc();

    await firestore.runTransaction((transaction) async {
      final replySnapshot = await transaction.get(replyRef);
      if (!replySnapshot.exists) {
        throw StateError('Reply not found');
      }
      transaction.set(nestedReplyRef, {
        'userId': uid,
        'content': content.trim(),
        'likes': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(replyRef, {'replyCount': FieldValue.increment(1)});
    });
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
    final followerRef = creatorRef.collection('followers').doc(uid);
    await firestore.runTransaction((transaction) async {
      final followSnapshot = await transaction.get(followRef);
      if (follow && !followSnapshot.exists) {
        transaction.set(followRef, {
          'creatorUid': creatorUid,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        transaction.set(followerRef, {
          'followerUid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        transaction.set(creatorRef, {
          'followerCount': FieldValue.increment(1),
        }, SetOptions(merge: true));
      } else if (!follow && followSnapshot.exists) {
        transaction.delete(followRef);
        transaction.delete(followerRef);
        transaction.set(creatorRef, {
          'followerCount': FieldValue.increment(-1),
        }, SetOptions(merge: true));
      }
    });
  }

  Future<void> updateRecipeVisibility({
    required String recipeId,
    required bool isPublished,
  }) async {
    final uid = _requiredUid();
    final recipeRef = firestore.collection('recipes').doc(recipeId);

    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(recipeRef);
      if (!snapshot.exists) {
        throw StateError('Recipe not found');
      }

      final data = snapshot.data() ?? {};
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

  static String _firstNotBlank(List<String?> values) {
    for (final value in values) {
      final normalized = value?.trim() ?? '';
      if (normalized.isNotEmpty) return normalized;
    }
    return '';
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
