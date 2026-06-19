part of 'explore_remote_datasource.dart';

/// Extension providing action methods for the ExploreRemoteDataSource.
///
/// Contains all write operations and user interactions including ratings,
/// comments, likes, replies, follows, and recipe visibility management.
/// Each action method handles the complete transaction flow with appropriate
/// Firestore updates and notification triggering.
extension ExploreRemoteDataSourceActions on ExploreRemoteDataSource {
  /// Submits or updates a user's rating for a specific recipe.
  ///
  /// Calculates the new average rating based on the existing rating count
  /// and total sum. Handles both new ratings and updates to existing ratings.
  /// Sends a notification to the recipe creator if this is a new rating.
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

    // Execute the entire rating update as a single atomic transaction.
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

      // Determine if this is a new rating or an update to an existing one.
      final hasExistingRating = ratingSnapshot.exists;
      isNewRating = !hasExistingRating;
      final ratingData = ratingSnapshot.data();
      final oldRating = hasExistingRating && ratingData != null
          ? _doubleValue(ratingData['rating'])
          : 0.0;
      // Calculate the new count, total sum, and average after the rating change.
      final nextCount = hasExistingRating ? currentCount : currentCount + 1;
      final nextTotal = hasExistingRating
          ? currentTotal - oldRating + rating
          : currentTotal + rating;
      final nextAverage = nextCount == 0 ? 0.0 : nextTotal / nextCount;
      final createdAt = hasExistingRating && ratingData != null
          ? ratingData['createdAt']
          : FieldValue.serverTimestamp();

      // Update the user's rating document with the new rating value.
      transaction.set(ratingRef, {
        'userId': uid,
        'rating': rating,
        'createdAt': createdAt,
      }, SetOptions(merge: true));
      // Update the recipe document with the recalculated average and count.
      transaction.update(recipeRef, {
        'averageRating': nextAverage,
        'ratingCount': nextCount,
      });
    });

    // Send a notification to the recipe creator only for new ratings.
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

  /// Adds a new comment to a recipe.
  ///
  /// Creates a comment document in the recipe's comments subcollection and
  /// increments the recipe's comment count. Sends a notification to the
  /// recipe creator about the new comment.
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

      // Create the new comment document with the user's content.
      transaction.set(commentRef, {
        'userId': uid,
        'content': content.trim(),
        'likes': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Increment the total comment count on the recipe.
      transaction.update(recipeRef, {'commentCount': FieldValue.increment(1)});
    });

    // Notify the recipe creator about the new comment.
    await _notifyUser(
      receiverUid: ownerUid,
      type: 'newComment',
      title: 'New Comment',
      message:
      '${await _currentUserName()} commented on $recipeTitle: ${_shortText(content)}',
    );
  }

  /// Increments the view count for a recipe.
  ///
  /// Updates the totalViews field on the recipe document by one.
  /// This is a simple update without transaction requirements.
  Future<void> incrementViewCount(String recipeId) async {
    final recipeRef = firestore.collection('recipes').doc(recipeId);
    await recipeRef.update({'totalViews': FieldValue.increment(1)});
  }

  /// Toggles a user's like on a comment.
  ///
  /// If the user has already liked the comment, removes the like.
  /// If the user has not liked the comment, adds a new like.
  /// Sends a notification to the comment owner when a new like is added.
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
        // Unlike: remove the like document and decrement the count.
        transaction.delete(likeRef);
        transaction.update(commentRef, {'likes': FieldValue.increment(-1)});
      } else {
        // Like: create the like document and increment the count.
        isNewLike = true;
        transaction.set(likeRef, {
          'userId': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(commentRef, {'likes': FieldValue.increment(1)});
      }
    });

    // Send notification only when a new like is added (not when removed).
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

  /// Adds a reply to an existing comment.
  ///
  /// Creates a reply document in the comment's replies subcollection and
  /// increments the comment's reply count. Sends a notification to the
  /// original comment owner about the new reply.
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
      // Create the new reply document.
      transaction.set(replyRef, {
        'userId': uid,
        'content': content.trim(),
        'likes': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Increment the reply count on the parent comment.
      transaction.update(commentRef, {'replyCount': FieldValue.increment(1)});
    });

    // Notify the comment owner about the new reply.
    await _notifyUser(
      receiverUid: commentOwnerUid,
      type: 'newReply',
      title: 'New Reply',
      message:
      '${await _currentUserName()} replied on $recipeTitle: ${_shortText(content)}',
    );
  }

  /// Toggles a user's like on a reply.
  ///
  /// Handles both adding and removing likes on reply documents.
  /// Sends a notification to the reply owner when a new like is added.
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
        // Unlike: remove the like document and decrement the count.
        transaction.delete(likeRef);
        transaction.update(replyRef, {'likes': FieldValue.increment(-1)});
      } else {
        // Like: create the like document and increment the count.
        isNewLike = true;
        transaction.set(likeRef, {
          'userId': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
        transaction.update(replyRef, {'likes': FieldValue.increment(1)});
      }
    });

    // Send notification only when a new like is added.
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

  /// Adds a nested reply to an existing reply (reply-to-reply).
  ///
  /// Creates a reply document in the nested replies subcollection and
  /// increments the parent reply's reply count. Sends a notification to
  /// the parent reply owner about the new nested reply.
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
      // Create the new nested reply document.
      transaction.set(nestedReplyRef, {
        'userId': uid,
        'content': content.trim(),
        'likes': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Increment the reply count on the parent reply.
      transaction.update(replyRef, {'replyCount': FieldValue.increment(1)});
    });

    // Notify the parent reply owner about the new nested reply.
    await _notifyUser(
      receiverUid: replyOwnerUid,
      type: 'newReply',
      title: 'New Reply',
      message:
      '${await _currentUserName()} replied on $recipeTitle: ${_shortText(content)}',
    );
  }

  /// Follows or unfollows a creator.
  ///
  /// Creates or removes a following document in the user's followingCreators
  /// subcollection and updates the creator's follower count. Sends a
  /// notification to the creator when a new follow occurs.
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
        // Follow action: create the following document and increment follower count.
        transaction.set(followRef, {
          'creatorUid': creatorUid,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        transaction.set(creatorRef, {
          'followerCount': FieldValue.increment(1),
        }, SetOptions(merge: true));
      } else if (!follow && followSnapshot.exists) {
        // Unfollow action: delete the following document and decrement follower count.
        transaction.delete(followRef);
        transaction.set(creatorRef, {
          'followerCount': FieldValue.increment(-1),
        }, SetOptions(merge: true));
      }
    });

    // Send notification only when following (not when unfollowing).
    if (follow) {
      await _notifyUser(
        receiverUid: creatorUid,
        type: 'newFollower',
        title: 'New Follower',
        message: '${await _currentUserName()} follows you.',
      );
    }
  }

  /// Updates the visibility status of a recipe (public or private).
  ///
  /// Only the recipe creator can change visibility. When a recipe is made
  /// public for the first time, sends notifications to all followers of
  /// the creator about the new recipe publication.
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
      // Determine if this change should trigger follower notifications.
      // Conditions: publishing, changing from non-public to public, and recipe is finalized.
      shouldNotifyFollowers =
          isPublished &&
              _stringValue(data['visibility']) != 'public' &&
              data['isFinalized'] != false;
      recipeTitle = _stringValue(data['name'], fallback: 'a new recipe');
      final creatorUid = _stringValue(data['creatorId']).isNotEmpty
          ? _stringValue(data['creatorId'])
          : _stringValue(data['creatorUid']);
      // Verify that the current user is the recipe creator.
      if (creatorUid != uid) {
        throw StateError('Only the recipe creator can change visibility.');
      }

      // Update the visibility status and the last updated timestamp.
      transaction.update(recipeRef, {
        'visibility': isPublished ? 'public' : 'private',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    // Send follower notifications only when a recipe is first published publicly.
    if (shouldNotifyFollowers) {
      await _notifyFollowersOfNewRecipe(
        recipeOwnerUid: uid,
        recipeTitle: recipeTitle,
      );
      // Record when the public notification was sent to avoid duplicate notifications.
      await recipeRef.update({
        'publicNotificationSentAt': FieldValue.serverTimestamp(),
      });
    }
  }
}