part of 'explore_remote_datasource.dart';

extension ExploreRemoteDataSourceNotifications on ExploreRemoteDataSource {
  // Retrieves the current user's UID or throws an authentication exception if missing.
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

  /*
   * Creates a notification document in Firestore and optionally sends a push notification.
   * Skips if receiver or sender is missing or if sender equals receiver.
   * The original action continues regardless of notification failures.
   */
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
      // Write notification to Firestore as the source of truth.
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
      // Check user preference before sending push.
      if (!await _isNotificationEnabled(receiverUid: receiverUid, type: type)) {
        return;
      }

      // Attempt to send push notification to all device tokens.
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

  // Checks if a specific notification type is enabled for the receiver.
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

  // Maps notification type strings to Firestore preference document IDs.
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

  /*
   * Sends a push notification to all FCM tokens associated with the receiver.
   * Any token that fails is skipped; overall failure does not throw.
   */
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
      // Extract and clean token strings from the user document.
      final tokens = rawTokens is Iterable
          ? rawTokens
          .map((token) => token?.toString().trim() ?? '')
          .where((token) => token.isNotEmpty)
          .toSet()
          : <String>{};

      // Send push to each valid token individually.
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

  // Fetches the current user's display name or returns a default.
  Future<String> _currentUserName() async {
    final uid = auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return 'Someone';
    final doc = await firestore.collection('users').doc(uid).get();
    return _stringValue(doc.data()?['name'], fallback: 'Someone');
  }

  // Extracts creator UID from recipe data, preferring 'creatorId' over 'creatorUid'.
  String _recipeCreatorUid(Map<String, dynamic> data) {
    final creatorId = _stringValue(data['creatorId']);
    if (creatorId.isNotEmpty) return creatorId;
    return _stringValue(data['creatorUid']);
  }

  // Determines if a recipe is publicly visible and finalized.
  bool _isPublicFinalizedRecipe(Map<String, dynamic> data) {
    return _stringValue(data['visibility']) == 'public' &&
        data['isFinalized'] != false;
  }

  // Truncates text to approximately 70 characters, preserving word spacing.
  String _shortText(String value) {
    final text = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (text.length <= 70) return text;
    return '${text.substring(0, 67)}...';
  }

  /*
   * Extracts a recipe ID from a reply path and fetches the recipe title.
   * Returns a fallback string if the path is malformed or the recipe is missing.
   */
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

  /*
   * Notifies all followers of a recipe creator when a new recipe is posted.
   * Each follower receives a separate notification with the creator's name and recipe title.
   */
  Future<void> _notifyFollowersOfNewRecipe({
    required String recipeOwnerUid,
    required String recipeTitle,
  }) async {
    if (recipeOwnerUid.isEmpty) return;
    try {
      final creatorName = await _currentUserName();
      final followerUids = await _getFollowerUids(recipeOwnerUid);

      // Send a notification to every follower individually.
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

  /*
   * Retrieves all user UIDs that follow a given recipe creator.
   * Scans the entire users collection and checks each user's followingCreators subcollection.
   */
  Future<List<String>> _getFollowerUids(String recipeOwnerUid) async {
    final followerUids = <String>[];
    final usersSnapshot = await firestore.collection('users').get();

    // Iterate through all users to find those following the recipe owner.
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
}