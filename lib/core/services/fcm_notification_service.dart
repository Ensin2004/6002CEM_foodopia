import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';

class FcmNotificationService {
  static const MethodChannel _channel = MethodChannel('foodopia/notifications');

  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await _saveCurrentToken();

    messaging.onTokenRefresh.listen((token) async {
      await _saveToken(token);
    });

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
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

    try {
      await _channel.invokeMethod<bool>('requestPermission');
      await _channel.invokeMethod<void>('scheduleNotification', {
        'id': Random().nextInt(1 << 31),
        'notificationKey': 'fcm_${message.messageId ?? DateTime.now()}',
        'title': title,
        'message': body,
        'scheduledAt': DateTime.now()
            .add(const Duration(seconds: 1))
            .millisecondsSinceEpoch,
      });
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
