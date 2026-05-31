import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FcmNotificationService {
  static const MethodChannel _channel = MethodChannel('foodopia/notifications');
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _notificationSubscription;
  static StreamSubscription<String>? _tokenSubscription;
  static StreamSubscription<RemoteMessage>? _messageSubscription;
  static final Set<String> _shownNotificationKeys = <String>{};
  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (!_isInitialized) {
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      _isInitialized = true;
    }

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await _saveCurrentToken();

    await _tokenSubscription?.cancel();
    _tokenSubscription = messaging.onTokenRefresh.listen((token) async {
      await _saveToken(token);
    });

    await _messageSubscription?.cancel();
    _messageSubscription = FirebaseMessaging.onMessage.listen(
      _showForegroundNotification,
    );
    _watchFirestoreNotifications();
  }

  static Future<void> _saveCurrentToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) return;
    await _saveToken(token);
  }

  static Future<void> _saveToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty || token.isEmpty) return;

    await _removeTokenFromOtherUsers(uid: uid, token: token);
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  static Future<void> _removeTokenFromOtherUsers({
    required String uid,
    required String token,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('fcmTokens', arrayContains: token)
          .get();
      final batch = FirebaseFirestore.instance.batch();
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

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final type = message.data['type']?.toString() ?? '';
    final enabled = await _isNotificationEnabledForType(uid: uid, type: type);
    if (!enabled) return;

    final title =
        message.notification?.title ?? message.data['title']?.toString();
    final body = message.notification?.body ?? message.data['body']?.toString();
    if (title == null || body == null) return;

    final notificationId = message.data['notificationId']?.toString() ?? '';
    final dedupeKey = notificationId.isEmpty
        ? 'fcm_${message.messageId ?? DateTime.now().millisecondsSinceEpoch}'
        : notificationId;
    if (!_shownNotificationKeys.add(dedupeKey)) return;

    await _showNativeNotification(
      title: title,
      body: body,
      key: 'notification_$dedupeKey',
    );
  }

  static void _watchFirestoreNotifications() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    _notificationSubscription?.cancel();
    final startedAt = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(seconds: 10)),
    );
    var hasDeliveredInitialSnapshot = false;
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
            if (!hasDeliveredInitialSnapshot) {
              for (final change in snapshot.docChanges) {
                if (change.type == DocumentChangeType.added) {
                  _shownNotificationKeys.add(change.doc.id);
                }
              }
              hasDeliveredInitialSnapshot = true;
              return;
            }

            for (final change in snapshot.docChanges) {
              if (change.type != DocumentChangeType.added) continue;
              if (!_shownNotificationKeys.add(change.doc.id)) continue;
              final data = change.doc.data() ?? const <String, dynamic>{};
              if (data['createdAt'] == null) continue;
              final type = data['type']?.toString() ?? '';
              final enabled = await _isNotificationEnabledForType(
                uid: uid,
                type: type,
              );
              if (!enabled) continue;
              final title = data['title']?.toString() ?? 'Foodopia';
              final body =
                  data['message']?.toString() ?? 'You have a new notification.';
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

  static Future<bool> _isNotificationEnabledForType({
    required String uid,
    required String type,
  }) async {
    if (uid.isEmpty) return true;
    final isAdmin = await _isAdmin(uid);
    const adminTypes = {'newUser', 'systemRating'};
    if (isAdmin && !adminTypes.contains(type)) return false;
    if (!isAdmin && adminTypes.contains(type)) return false;

    final preferenceId = _preferenceIdForNotificationType(type);
    if (preferenceId == null) return true;

    try {
      final preferenceDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notification_preferences')
          .doc(preferenceId)
          .get();
      final enabled = preferenceDoc.data()?['enabled'];
      return enabled is bool ? enabled : true;
    } on FirebaseException {
      return true;
    }
  }

  static Future<bool> _isAdmin(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      return doc.data()?['role']?.toString().toLowerCase() == 'admin';
    } on FirebaseException {
      return false;
    }
  }

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
      default:
        return null;
    }
  }

  static Future<void> _showNativeNotification({
    required String title,
    required String body,
    required String key,
  }) async {
    try {
      await _channel.invokeMethod<bool>('requestPermission');
      final shown = await _channel.invokeMethod<bool>('showNotificationNow', {
        'id': key.hashCode & 0x7fffffff,
        'title': title,
        'message': body,
        'channelId': 'foodopia_social_notifications',
      });
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

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}
