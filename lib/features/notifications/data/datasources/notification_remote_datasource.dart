import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_notification_model.dart';

class NotificationRemoteDataSource {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  const NotificationRemoteDataSource({
    required this.firestore,
    required this.auth,
  });

  Future<List<AppNotificationModel>> getNotifications() async {
    final uid = auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return [];

    final snapshot = await firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(80)
        .get();

    return snapshot.docs
        .map(AppNotificationModel.fromFirestore)
        .toList(growable: false);
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
