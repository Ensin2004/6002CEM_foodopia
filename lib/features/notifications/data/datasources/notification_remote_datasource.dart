import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/notification_preference.dart';
import '../models/app_notification_model.dart';

class NotificationRemoteDataSource {
  static const List<NotificationPreference> userDefaultPreferences = [
    NotificationPreference(
      id: 'new_follower_notification',
      title: 'New Follower Notification',
      description: 'Get a notification for new follower',
      enabled: true,
    ),
    NotificationPreference(
      id: 'new_rating_notification',
      title: 'New Rating Notification',
      description:
          'Receive a notification when your Recipe is being rated by user',
      enabled: true,
    ),
    NotificationPreference(
      id: 'new_comment_notification',
      title: 'New Comment Notification',
      description: 'Receive a notification when your recipe has comment',
      enabled: true,
    ),
    NotificationPreference(
      id: 'new_recipe_notification',
      title: 'New Recipe Notification',
      description: 'Receive a notification when followed creator posts',
      enabled: true,
    ),
    NotificationPreference(
      id: 'new_reply_notification',
      title: 'New Reply Notification',
      description: 'Receive a notification when someone replies you',
      enabled: true,
    ),
    NotificationPreference(
      id: 'new_like_notification',
      title: 'New Like Notification',
      description: 'Receive a notification when someone likes your comment',
      enabled: true,
    ),
    NotificationPreference(
      id: 'help_center_reply_notification',
      title: 'Help Center Reply Notification',
      description: 'Receive a notification when admin replies your ticket',
      enabled: true,
    ),
  ];

  static const List<NotificationPreference> adminDefaultPreferences = [
    NotificationPreference(
      id: 'new_user_notification',
      title: 'New User Notification',
      description: 'Receive a notification when a new user registers',
      enabled: true,
    ),
    NotificationPreference(
      id: 'system_rating_notification',
      title: 'System Rating Notification',
      description: 'Receive a notification when someone rates the system',
      enabled: true,
    ),
    NotificationPreference(
      id: 'new_help_ticket_notification',
      title: 'New Help Ticket Notification',
      description: 'Receive a notification when user submits help ticket',
      enabled: true,
    ),
    NotificationPreference(
      id: 'new_category_notification',
      title: 'New Category Notification',
      description: 'Receive a notification when user adds a new category',
      enabled: true,
    ),
  ];

  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  const NotificationRemoteDataSource({
    required this.firestore,
    required this.auth,
  });

  Future<List<AppNotificationModel>> getNotifications() async {
    final uid = auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return [];
    final isAdmin = await _isAdmin(uid);

    final snapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(80)
        .get();

    return snapshot.docs
        .where((doc) => _isAllowedType(doc.data()['type']?.toString(), isAdmin))
        .map(AppNotificationModel.fromFirestore)
        .toList(growable: false);
  }

  Future<List<NotificationPreference>> getPreferences() async {
    final uid = auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return userDefaultPreferences;

    await ensureDefaultPreferences();
    final defaults = await _defaultPreferencesForUid(uid);
    final snapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('notification_preferences')
        .get();
    final byId = {for (final doc in snapshot.docs) doc.id: doc.data()};

    return defaults
        .map((preference) {
          final data = byId[preference.id];
          final enabled = data?['enabled'];
          return preference.copyWith(
            enabled: enabled is bool ? enabled : preference.enabled,
          );
        })
        .toList(growable: false);
  }

  Future<void> ensureDefaultPreferences() async {
    final uid = auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    final userRef = firestore.collection('users').doc(uid);
    final defaultPreferences = await _defaultPreferencesForUid(uid);
    final collectionRef = userRef.collection('notification_preferences');
    final snapshot = await collectionRef.get();
    final existingIds = snapshot.docs.map((doc) => doc.id).toSet();

    final batch = firestore.batch();
    for (final preference in defaultPreferences) {
      final ref = collectionRef.doc(preference.id);
      if (existingIds.contains(preference.id)) {
        batch.set(ref, {
          'title': preference.title,
          'description': preference.description,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        batch.set(ref, {
          'title': preference.title,
          'description': preference.description,
          'enabled': preference.enabled,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }

    await batch.commit();
  }

  Future<void> updatePreference({
    required String preferenceId,
    required bool enabled,
  }) async {
    final uid = auth.currentUser?.uid ?? '';
    if (uid.isEmpty || preferenceId.isEmpty) return;

    final defaultPreferences = await _defaultPreferencesForUid(uid);
    final defaultPreference = defaultPreferences.firstWhere(
      (item) => item.id == preferenceId,
      orElse: () => NotificationPreference(
        id: preferenceId,
        title: preferenceId,
        description: '',
        enabled: enabled,
      ),
    );
    final userRef = firestore.collection('users').doc(uid);
    await userRef.collection('notification_preferences').doc(preferenceId).set({
      'title': defaultPreference.title,
      'description': defaultPreference.description,
      'enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<NotificationPreference>> _defaultPreferencesForUid(
    String uid,
  ) async {
    return await _isAdmin(uid)
        ? adminDefaultPreferences
        : userDefaultPreferences;
  }

  Future<bool> _isAdmin(String uid) async {
    if (uid.isEmpty) return false;
    final doc = await firestore.collection('users').doc(uid).get();
    return doc.data()?['role']?.toString().toLowerCase() == 'admin';
  }

  bool _isAllowedType(String? type, bool isAdmin) {
    const adminTypes = {
      'newUser',
      'systemRating',
      'newHelpTicket',
      'newCategory',
    };
    if (isAdmin) return adminTypes.contains(type);
    return !adminTypes.contains(type);
  }

  Future<void> markAsRead(String notificationId) async {
    final uid = auth.currentUser?.uid ?? '';
    if (uid.isEmpty || notificationId.isEmpty) return;

    await firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notificationId)
        .set({'isRead': true}, SetOptions(merge: true));
  }

  Future<void> markAllAsRead() async {
    final uid = auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    final snapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .get();
    final batch = firestore.batch();
    for (final doc in snapshot.docs) {
      batch.set(doc.reference, {'isRead': true}, SetOptions(merge: true));
    }
    await batch.commit();
  }
}
