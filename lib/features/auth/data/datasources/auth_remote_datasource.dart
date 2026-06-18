import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../../core/services/fcm_sender.dart';

/// Defines behavior for auth remote data source.
/// Handles authentication and user management with Firebase.
class AuthRemoteDataSource {
  // =========================================================================
  // CONSTANTS
  // =========================================================================

  /// Default notification preferences for new users.
  static const List<Map<String, String>> _defaultNotificationPreferences = [
    {
      'id': 'new_follower_notification',
      'title': 'New Follower Notification',
      'description': 'Get a notification for new follower',
    },
    {
      'id': 'new_rating_notification',
      'title': 'New Rating Notification',
      'description':
      'Receive a notification when your Recipe is being rated by user',
    },
    {
      'id': 'new_comment_notification',
      'title': 'New Comment Notification',
      'description': 'Receive a notification when your recipe has comment',
    },
    {
      'id': 'new_recipe_notification',
      'title': 'New Recipe Notification',
      'description': 'Receive a notification when followed creator posts',
    },
    {
      'id': 'new_reply_notification',
      'title': 'New Reply Notification',
      'description': 'Receive a notification when someone replies you',
    },
    {
      'id': 'new_like_notification',
      'title': 'New Like Notification',
      'description': 'Receive a notification when someone likes your comment',
    },
    {
      'id': 'help_center_reply_notification',
      'title': 'Help Center Reply Notification',
      'description': 'Receive a notification when admin replies your ticket',
    },
  ];

  // =========================================================================
  // DEPENDENCIES
  // =========================================================================

  /// Firebase Authentication instance.
  final firebase_auth.FirebaseAuth _auth;

  /// Firestore instance for database operations.
  final FirebaseFirestore _firestore;

  /// Firebase Messaging instance for push notifications.
  final FirebaseMessaging _fcm;

  /// Creates a auth remote data source instance.
  AuthRemoteDataSource({
    firebase_auth.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseMessaging? fcm,
  }) : _auth = auth ?? firebase_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _fcm = fcm ?? FirebaseMessaging.instance;

  // =========================================================================
  // AUTHENTICATION
  // =========================================================================

  /// Logs in a user with email and password.
  Future<firebase_auth.UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Creates a new user account with email and password.
  Future<firebase_auth.UserCredential> signup({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Runs the send email verification operation.
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// Checks whether an email is registered in the users collection.
  Future<bool> emailExistsInFirestore(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return false;

    final snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: trimmed)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  /// Sends a Firebase password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Handles the reload user operation.
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  /// Returns the current authenticated user.
  firebase_auth.User? getCurrentUser() {
    return _auth.currentUser;
  }

  // =========================================================================
  // FCM TOKEN MANAGEMENT
  // =========================================================================

  /// Gets the current FCM token.
  Future<String?> getFCMToken() async {
    return await _fcm.getToken();
  }

  /// Saves the FCM token to the user's document.
  Future<void> saveFcmToken(String uid) async {
    final token = await getFCMToken();
    if (token == null || token.isEmpty) return;

    await _removeFcmTokenFromOtherUsers(uid: uid, token: token);
    await _firestore.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  /// Removes the current FCM token from the user's document.
  Future<void> removeCurrentFcmToken() async {
    final uid = _auth.currentUser?.uid;
    final token = await getFCMToken();

    if (uid == null || uid.isEmpty || token == null || token.isEmpty) return;

    try {
      await _firestore.collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayRemove([token]),
      }, SetOptions(merge: true));
    } on FirebaseException {
      // Logout should still continue if token cleanup is blocked.
    }
  }

  /// Removes an FCM token from other users' documents.
  Future<void> _removeFcmTokenFromOtherUsers({
    required String uid,
    required String token,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('fcmTokens', arrayContains: token)
          .get();

      final batch = _firestore.batch();
      var hasUpdates = false;

      for (final doc in snapshot.docs) {
        if (doc.id == uid) continue;
        batch.set(doc.reference, {
          'fcmTokens': FieldValue.arrayRemove([token]),
        }, SetOptions(merge: true));
        hasUpdates = true;
      }

      if (hasUpdates) {
        await batch.commit();
      }
    } on FirebaseException {
      // Best-effort cleanup for shared test devices.
    }
  }

  // =========================================================================
  // USER MANAGEMENT
  // =========================================================================

  /// Saves user data to Firestore.
  Future<void> saveUserToFirestore({
    required String uid,
    required Map<String, dynamic> userData,
  }) async {
    await _firestore.collection('users').doc(uid).set(userData);
    await ensureNotificationPreferences(uid);
    await _notifyAdminsNewUser(uid: uid, userData: userData);
  }

  /// Notifies admins when a new user registers.
  Future<void> _notifyAdminsNewUser({
    required String uid,
    required Map<String, dynamic> userData,
  }) async {
    // Skip if the new user is an admin.
    if (userData['role']?.toString().toLowerCase() == 'admin') return;

    try {
      // Get the user's name or email.
      final rawName = userData['name']?.toString().trim() ?? '';
      final name = rawName.isNotEmpty
          ? rawName
          : userData['email']?.toString().trim() ?? 'A new user';

      // Get all admin users.
      final admins = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      // Send notification to each admin.
      for (final admin in admins.docs) {
        final adminUid = admin.id;
        if (adminUid.isEmpty || adminUid == uid) continue;

        // Create notification document.
        final notificationRef = await _firestore
            .collection('users')
            .doc(adminUid)
            .collection('notifications')
            .add({
          'type': 'newUser',
          'title': 'New User',
          'message': 'New user $name registered an account.',
          'isRead': false,
          'senderUid': uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Check if notification preference is enabled.
        if (!await _isAdminNotificationEnabled(
          adminUid: adminUid,
          preferenceId: 'new_user_notification',
        )) {
          continue;
        }

        // Send push notification.
        await _sendPushToUser(
          receiverUid: adminUid,
          title: 'New User',
          message: 'New user $name registered an account.',
          data: {
            'type': 'newUser',
            'notificationId': notificationRef.id,
            'senderUid': uid,
          },
        );
      }
    } on FirebaseException {
      // Admin notifications are best-effort and should not block signup.
    }
  }

  /// Checks if an admin notification preference is enabled.
  Future<bool> _isAdminNotificationEnabled({
    required String adminUid,
    required String preferenceId,
  }) async {
    final preferenceDoc = await _firestore
        .collection('users')
        .doc(adminUid)
        .collection('notification_preferences')
        .doc(preferenceId)
        .get();

    final enabled = preferenceDoc.data()?['enabled'];
    return enabled is bool ? enabled : true;
  }

  /// Sends a push notification to a user.
  Future<void> _sendPushToUser({
    required String receiverUid,
    required String title,
    required String message,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Get the user's FCM tokens.
      final userDoc = await _firestore
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

      // Send push to each token.
      for (final token in tokens) {
        await FcmSender.instance.sendToToken(
          deviceToken: token,
          title: title,
          body: message,
          data: data,
        );
      }
    } catch (_) {
      // Push is best-effort; Firestore keeps the in-app notification.
    }
  }

  // =========================================================================
  // NOTIFICATION PREFERENCES
  // =========================================================================

  /// Ensures notification preferences exist for a user.
  Future<void> ensureNotificationPreferences(String uid) async {
    if (uid.isEmpty) return;

    final userRef = _firestore.collection('users').doc(uid);
    final collectionRef = userRef.collection('notification_preferences');

    // Get existing preferences.
    final snapshot = await collectionRef.get();
    final existingIds = snapshot.docs.map((doc) => doc.id).toSet();

    // Create or update default preferences.
    final batch = _firestore.batch();

    for (final preference in _defaultNotificationPreferences) {
      final id = preference['id'] ?? '';
      if (id.isEmpty) continue;

      final ref = collectionRef.doc(id);

      if (existingIds.contains(id)) {
        // Update existing preference.
        batch.set(ref, {
          'title': preference['title'] ?? id,
          'description': preference['description'] ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        // Create new preference.
        batch.set(ref, {
          'title': preference['title'] ?? id,
          'description': preference['description'] ?? '',
          'enabled': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }

    await batch.commit();
  }

  // =========================================================================
  // USER DATA
  // =========================================================================

  /// Updates user data in Firestore.
  Future<void> updateUserInFirestore({
    required String uid,
    required Map<String, dynamic> userData,
  }) async {
    await _firestore.collection('users').doc(uid).update(userData);
  }

  /// Gets user data from Firestore.
  Future<DocumentSnapshot> getUserFromFirestore(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  /// Gets configured age groups from Firestore.
  Future<QuerySnapshot> getAgeGroups() async {
    return await _firestore
        .collection('app_config')
        .doc('age_groups')
        .collection('items')
        .orderBy('sortOrder')
        .get();
  }

  // =========================================================================
  // LOGOUT
  // =========================================================================

  /// Handles the logout operation.
  Future<void> logout() async {
    await removeCurrentFcmToken();
    await _auth.signOut();
  }
}