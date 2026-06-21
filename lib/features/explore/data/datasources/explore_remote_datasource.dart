import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/services/fcm_sender.dart';
import '../../domain/entities/explore_recipe.dart';
import '../models/explore_recipe_model.dart';

// Part files containing specialized functionality for the explore data source.
part 'explore_remote_datasource_actions.dart';
part 'explore_remote_datasource_community.dart';
part 'explore_remote_datasource_ingredients.dart';
part 'explore_remote_datasource_mapping.dart';
part 'explore_remote_datasource_notifications.dart';
part 'explore_remote_datasource_parsing.dart';
part 'explore_remote_datasource_types.dart';

/// Remote data source for exploring and retrieving recipe data from Firestore.
///
/// Handles all Firebase Firestore interactions related to recipe discovery,
/// including fetching lists of recipes, watching real-time updates, retrieving
/// detailed recipe information, and fetching creator profiles.
class ExploreRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  const ExploreRemoteDataSource({required this.firestore, required this.auth});

  /// Retrieves a list of public recipes from Firestore.
  ///
  /// Queries the 'recipes' collection for documents with visibility set to 'public',
  /// ordered by the most recently updated. Returns a [Future] that completes
  /// with a list of [ExploreRecipeModel] objects.
  Future<List<ExploreRecipeModel>> getRecipes() async {
    final snapshot = await firestore
        .collection('recipes')
        .where('visibility', isEqualTo: 'public')
        .orderBy('updatedAt', descending: true)
        .get();

    final recipes = <ExploreRecipeModel>[];
    for (final doc in snapshot.docs) {
      // Skip documents that do not represent a finalized public recipe.
      if (!_isPublicFinalizedRecipe(doc.data())) continue;
      recipes.add(await _recipeFromDoc(doc, includeCommunity: false));
    }
    return recipes;
  }

  /// Provides a stream of real-time updates for public recipes.
  ///
  /// Returns a [Stream] that emits a new list of [ExploreRecipeModel] whenever
  /// changes occur to recipes, following creators, or saved recipes. The stream
  /// uses a debouncing mechanism to prevent excessive refreshes during rapid
  /// consecutive updates.
  Stream<List<ExploreRecipeModel>> watchRecipes() {
    late final StreamController<List<ExploreRecipeModel>> controller;
    final subscriptions = <StreamSubscription<dynamic>>[];
    var isFetching = false;
    var shouldFetchAgain = false;

    /// Internal function to emit the current list of recipes.
    /// Handles debouncing by tracking fetch state and coalescing multiple requests.
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
        // Listen to changes in the recipes collection.
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
          // Listen to changes in followed creators for the current user.
          subscriptions.add(
            firestore
                .collection('users')
                .doc(uid)
                .collection('followingCreators')
                .snapshots()
                .listen((_) => emitRecipes()),
          );
          // Listen to changes in saved recipes for the current user.
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
        // Clean up all active subscriptions when the stream is cancelled.
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );
    return controller.stream;
  }

  /// Provides a stream of real-time updates for a single recipe detail.
  ///
  /// Takes a [recipeId] and returns a [Stream] that emits the updated
  /// [ExploreRecipeModel] whenever the recipe, its ratings, comments, or related
  /// user data changes. Includes community data when emitting updates.
  Stream<ExploreRecipeModel> watchRecipeDetail(String recipeId) {
    final recipeRef = firestore.collection('recipes').doc(recipeId);
    late final StreamController<ExploreRecipeModel> controller;
    final subscriptions = <StreamSubscription<dynamic>>[];
    var isFetching = false;
    var shouldFetchAgain = false;

    /// Internal function to emit the current recipe detail.
    /// Fetches the latest data and handles error states.
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
        // Listen to changes in the main recipe document.
        subscriptions.add(recipeRef.snapshots().listen((_) => emitRecipe()));
        // Listen to changes in the recipe's ratings subcollection.
        subscriptions.add(
          recipeRef
              .collection('ratings')
              .snapshots()
              .listen((_) => emitRecipe()),
        );
        // Listen to changes in the recipe's comments subcollection.
        subscriptions.add(
          recipeRef
              .collection('comments')
              .snapshots()
              .listen((_) => emitRecipe()),
        );
        final uid = auth.currentUser?.uid ?? '';
        if (uid.isNotEmpty) {
          // Listen to changes in followed creators for the current user.
          subscriptions.add(
            firestore
                .collection('users')
                .doc(uid)
                .collection('followingCreators')
                .snapshots()
                .listen((_) => emitRecipe()),
          );
          // Listen to changes in saved recipes for the current user.
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
        // Clean up all active subscriptions when the stream is cancelled.
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );
    return controller.stream;
  }

  /// Fetches the complete detail of a single recipe.
  ///
  /// Retrieves the recipe document from Firestore and constructs a full
  /// [ExploreRecipeModel] including community data. Throws a [StateError]
  /// if the recipe document does not exist.
  Future<ExploreRecipeModel> getRecipeDetail(String recipeId) async {
    final doc = await firestore.collection('recipes').doc(recipeId).get();
    if (!doc.exists) {
      throw StateError('Recipe not found');
    }

    return _recipeFromDoc(doc, includeCommunity: true);
  }

  /// Retrieves detailed information about a recipe creator.
  ///
  /// Fetches the creator's profile, recipe count, following count, and list
  /// of published recipes. Returns a [ExploreCreatorDetail] object containing
  /// all relevant creator information. Throws a [StateError] if the creator
  /// UID is empty.
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
}