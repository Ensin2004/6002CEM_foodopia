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

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final title =
        message.notification?.title ?? message.data['title']?.toString();
    final body = message.notification?.body ?? message.data['body']?.toString();
    if (title == null || body == null) return;

    await _showNativeNotification(
      title: title,
      body: body,
      key: 'fcm_${message.messageId ?? DateTime.now()}',
    );
  }

  static void _watchFirestoreNotifications() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return;

    _notificationSubscription?.cancel();
    final startedAt = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(seconds: 10)),
    );
    _notificationSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .where('createdAt', isGreaterThan: startedAt)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen(
          (snapshot) {
            for (final change in snapshot.docChanges) {
              if (change.type != DocumentChangeType.added) continue;
              if (!_shownNotificationKeys.add(change.doc.id)) continue;
              final data = change.doc.data() ?? const <String, dynamic>{};
              if (data['createdAt'] == null) continue;
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
