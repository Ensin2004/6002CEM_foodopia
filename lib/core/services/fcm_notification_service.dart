import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service for handling Firebase Cloud Messaging (FCM) notifications.
/// Manages token registration, foreground notifications, and Firestore notifications.
class FcmNotificationService {
  // =========================================================================
  // CONSTANTS
  // =========================================================================

  /// Method channel for native notification handling.
  static const MethodChannel _channel = MethodChannel('foodopia/notifications');

  // =========================================================================
  // STATE
  // =========================================================================

  /// Subscription to Firestore notification changes.
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _notificationSubscription;

  /// Subscription to FCM token refresh events.
  static StreamSubscription<String>? _tokenSubscription;

  /// Subscription to incoming FCM messages.
  static StreamSubscription<RemoteMessage>? _messageSubscription;

  /// Set of already shown notification keys for deduplication.
  static final Set<String> _shownNotificationKeys = <String>{};

  /// Whether the service has been initialized.
  static bool _isInitialized = false;

  // =========================================================================
  // INITIALIZATION
  // =========================================================================

  /// Initializes the FCM notification service.
  static Future<void> initialize() async {
    // Set up background message handler.
    if (!_isInitialized) {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      _isInitialized = true;
    }

    // Get the messaging instance.
    final messaging = FirebaseMessaging.instance;

    // Request notification permissions.
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Save the current FCM token.
    await _saveCurrentToken();

    // Subscribe to token refresh events.
    await _tokenSubscription?.cancel();
    _tokenSubscription = messaging.onTokenRefresh.listen((token) async {
      await _saveToken(token);
    });

    // Subscribe to foreground messages.
    await _messageSubscription?.cancel();
    _messageSubscription = FirebaseMessaging.onMessage.listen(
      _showForegroundNotification,
    );

    // Start listening to Firestore notifications.
    _watchFirestoreNotifications();
  }

  // =========================================================================
  // TOKEN MANAGEMENT
  // =========================================================================

  /// Saves the current FCM token.
  static Future<void> _saveCurrentToken() async {
    // Get the token.
    final token = await FirebaseMessaging.instance.getToken();

    // Return if token is invalid.
    if (token == null || token.isEmpty) return;

    // Save the token.
    await _saveToken(token);
  }

  /// Saves an FCM token to the user's document.
  static Future<void> _saveToken(String token) async {
    // Get the current user ID.
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // Return if user is not authenticated.
    if (uid == null || uid.isEmpty || token.isEmpty) return;

    // Remove token from other users.
    await _removeTokenFromOtherUsers(uid: uid, token: token);

    // Save token to user document.
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  /// Removes a token from other users' documents.
  static Future<void> _removeTokenFromOtherUsers({
    required String uid,
    required String token,
  }) async {
    try {
      // Find users with this token.
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('fcmTokens', arrayContains: token)
          .get();

      // Start a batch write.
      final batch = FirebaseFirestore.instance.batch();
      var hasUpdates = false;

      // Remove token from other users.
      for (final doc in snapshot.docs) {
        if (doc.id == uid) continue;
        batch.set(doc.reference, {
          'fcmTokens': FieldValue.arrayRemove([token]),
        }, SetOptions(merge: true));
        hasUpdates = true;
      }

      // Commit the batch.
      if (hasUpdates) {
        await batch.commit();
      }
    } on FirebaseException {
      // Best-effort cleanup for shared test devices.
    }
  }

  // =========================================================================
  // FOREGROUND NOTIFICATIONS
  // =========================================================================

  /// Shows a foreground notification when an FCM message is received.
  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    // Get the current user ID.
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    // Check if notification type is enabled.
    final type = message.data['type']?.toString() ?? '';
    final enabled = await _isNotificationEnabledForType(uid: uid, type: type);
    if (!enabled) return;

    // Get notification details.
    final title =
        message.notification?.title ?? message.data['title']?.toString();
    final body = message.notification?.body ?? message.data['body']?.toString();

    // Return if missing required fields.
    if (title == null || body == null) return;

    // Generate deduplication key.
    final notificationId = message.data['notificationId']?.toString() ?? '';
    final dedupeKey = notificationId.isEmpty
        ? 'fcm_${message.messageId ?? DateTime.now().millisecondsSinceEpoch}'
        : notificationId;

    // Skip if already shown.
    if (!_shownNotificationKeys.add(dedupeKey)) return;

    // Show native notification.
    await _showNativeNotification(
      title: title,
      body: body,
      key: 'notification_$dedupeKey',
    );
  }

  // =========================================================================
  // FIRESTORE NOTIFICATIONS
  // =========================================================================

  /// Watches Firestore for new notifications.
  static void _watchFirestoreNotifications() {
    // Get the current user ID.
    final uid = FirebaseAuth.instance.currentUser?.uid;

    // Return if user is not authenticated.
    if (uid == null || uid.isEmpty) return;

    // Cancel existing subscription.
    _notificationSubscription?.cancel();

    // Set query start time.
    final startedAt = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(seconds: 10)),
    );

    // Track initial snapshot delivery.
    var hasDeliveredInitialSnapshot = false;

    // Listen to Firestore notifications.
    _notificationSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .where('createdAt', isGreaterThan: startedAt)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen(
          (snapshot) async {
        // Handle initial snapshot - mark all as shown.
        if (!hasDeliveredInitialSnapshot) {
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              _shownNotificationKeys.add(change.doc.id);
            }
          }
          hasDeliveredInitialSnapshot = true;
          return;
        }

        // Process new notifications.
        for (final change in snapshot.docChanges) {
          // Skip non-added changes.
          if (change.type != DocumentChangeType.added) continue;

          // Skip if already shown.
          if (!_shownNotificationKeys.add(change.doc.id)) continue;

          // Get notification data.
          final data = change.doc.data() ?? const <String, dynamic>{};

          // Skip if no timestamp.
          if (data['createdAt'] == null) continue;

          // Check if notification type is enabled.
          final type = data['type']?.toString() ?? '';
          final enabled = await _isNotificationEnabledForType(
            uid: uid,
            type: type,
          );
          if (!enabled) continue;

          // Get title and body.
          final title = data['title']?.toString() ?? 'Foodopia';
          final body =
              data['message']?.toString() ?? 'You have a new notification.';

          // Show native notification.
          _showNativeNotification(
            title: title,
            body: body,
            key: 'firestore_${change.doc.id}',
          );
        }
      },
      onError: (Object error) {
        debugPrint(
          '[NotificationWatcher] Firestore listener error: $error',
        );
      },
    );
  }

  // =========================================================================
  // NOTIFICATION PREFERENCES
  // =========================================================================

  /// Checks if a notification type is enabled for a user.
  static Future<bool> _isNotificationEnabledForType({
    required String uid,
    required String type,
  }) async {
    // Return default if no user.
    if (uid.isEmpty) return true;

    // Check if user is admin.
    final isAdmin = await _isAdmin(uid);

    // Admin notification types.
    const adminTypes = {
      'newUser',
      'systemRating',
      'newHelpTicket',
      'newCategory',
    };

    // Skip non-admin notifications for admins.
    if (isAdmin && !adminTypes.contains(type)) return false;

    // Skip admin notifications for non-admins.
    if (!isAdmin && adminTypes.contains(type)) return false;

    // Get preference ID for the notification type.
    final preferenceId = _preferenceIdForNotificationType(type);

    // Return default if no preference mapping.
    if (preferenceId == null) return true;

    try {
      // Get the preference document.
      final preferenceDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notification_preferences')
          .doc(preferenceId)
          .get();

      // Return preference value or default.
      final enabled = preferenceDoc.data()?['enabled'];
      return enabled is bool ? enabled : true;
    } on FirebaseException {
      // Return default on error.
      return true;
    }
  }

  /// Checks if a user is an admin.
  static Future<bool> _isAdmin(String uid) async {
    try {
      // Get the user document.
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      // Check if role is admin.
      return doc.data()?['role']?.toString().toLowerCase() == 'admin';
    } on FirebaseException {
      // Return false on error.
      return false;
    }
  }

  /// Maps a notification type to a preference ID.
  static String? _preferenceIdForNotificationType(String type) {
    switch (type) {
      case 'newFollower':
      case 'follow':
        return 'new_follower_notification';
      case 'newRating':
      case 'rating':
        return 'new_rating_notification';
      case 'newComment':
      case 'comment':
        return 'new_comment_notification';
      case 'newRecipe':
      case 'newPost':
        return 'new_recipe_notification';
      case 'newReply':
      case 'reply':
        return 'new_reply_notification';
      case 'newLike':
      case 'like':
        return 'new_like_notification';
      case 'newUser':
        return 'new_user_notification';
      case 'systemRating':
        return 'system_rating_notification';
      case 'newHelpTicket':
        return 'new_help_ticket_notification';
      case 'newCategory':
        return 'new_category_notification';
      case 'helpReply':
        return 'help_center_reply_notification';
      default:
        return null;
    }
  }

  // =========================================================================
  // NATIVE NOTIFICATION
  // =========================================================================

  /// Shows a native notification using platform channels.
  static Future<void> _showNativeNotification({
    required String title,
    required String body,
    required String key,
  }) async {
    try {
      // Request permission.
      await _channel.invokeMethod<bool>('requestPermission');

      // Show notification.
      final shown = await _channel.invokeMethod<bool>('showNotificationNow', {
        'id': key.hashCode & 0x7fffffff,
        'title': title,
        'message': body,
        'channelId': 'foodopia_social_notifications',
      });

      // Log permission denial.
      if (shown == false) {
        debugPrint(
          '[NotificationWatcher] Android notification permission is not granted.',
        );
      }
    } on PlatformException {
      // FCM notification still exists in the in-app notification list.
    } on MissingPluginException {
      // Allows non-Android platforms to ignore native local display.
    }
  }
}

// =========================================================================
// BACKGROUND HANDLER
// =========================================================================

/// Handles FCM messages when the app is in the background.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase for background execution.
  await Firebase.initializeApp();
}