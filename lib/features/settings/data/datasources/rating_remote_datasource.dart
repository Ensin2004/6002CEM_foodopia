// Handles remote data access for rating.

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/services/fcm_sender.dart';

/// Defines behavior for rating remote data source.
class RatingRemoteDataSource {
  final FirebaseFirestore _firestore;

  /// Creates a rating remote data source instance.
  RatingRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore
      .collection('support_center')
      .doc('app_rating_feedback')
      .collection('items');

  /// Loads data for the get user rating operation.
  Future<DocumentSnapshot> getUserRating(String userId) async {
    return await _collection.doc(userId).get();
  }

  /// Loads data for the get all ratings operation.
  Future<QuerySnapshot> getAllRatings() async {
    return await _collection.get();
  }

  /// Runs the save rating operation.
  Future<void> saveRating(String userId, Map<String, dynamic> data) async {
    final doc = _collection.doc(userId);
    final existing = await doc.get();
    final writeData = Map<String, dynamic>.from(data);
    if (existing.exists) {
      writeData.remove('createdAt');
    }
    await doc.set(writeData, SetOptions(merge: true));
    await _notifyAdminsSystemRating(userId: userId, data: writeData);
  }

  Future<void> _notifyAdminsSystemRating({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final userName = data['userName']?.toString().trim() ?? '';
      final stars = data['stars']?.toString() ?? '';
      final name = userName.isEmpty ? 'Someone' : userName;
      final message = stars.isEmpty
          ? '$name submitted a new system rating.'
          : '$name submitted a new $stars star system rating.';
      final admins = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      for (final admin in admins.docs) {
        final adminUid = admin.id;
        if (adminUid.isEmpty || adminUid == userId) continue;
        final notificationRef = await _firestore
            .collection('users')
            .doc(adminUid)
            .collection('notifications')
            .add({
              'type': 'systemRating',
              'title': 'New Rating On System',
              'message': message,
              'isRead': false,
              'senderUid': userId,
              'createdAt': FieldValue.serverTimestamp(),
            });

        if (!await _isAdminNotificationEnabled(
          adminUid: adminUid,
          preferenceId: 'system_rating_notification',
        )) {
          continue;
        }

        await _sendPushToUser(
          receiverUid: adminUid,
          title: 'New Rating On System',
          message: message,
          data: {
            'type': 'systemRating',
            'notificationId': notificationRef.id,
            'senderUid': userId,
          },
        );
      }
    } on FirebaseException {
      // Rating save already succeeded; admin notification is best-effort.
    }
  }

  Future<bool> _isAdminNotificationEnabled({
    required String adminUid,
    required String preferenceId,
  }) async {
    final userDoc = await _firestore.collection('users').doc(adminUid).get();
    final preferences = userDoc.data()?['notificationPreferences'];
    if (preferences is Map && preferences[preferenceId] is bool) {
      return preferences[preferenceId] as bool;
    }

    final preferenceDoc = await _firestore
        .collection('users')
        .doc(adminUid)
        .collection('notification_preferences')
        .doc(preferenceId)
        .get();
    final enabled = preferenceDoc.data()?['enabled'];
    return enabled is bool ? enabled : true;
  }

  Future<void> _sendPushToUser({
    required String receiverUid,
    required String title,
    required String message,
    required Map<String, dynamic> data,
  }) async {
    try {
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

  /// Runs the delete rating operation.
  Future<void> deleteRating(String userId) async {
    await _collection.doc(userId).delete();
  }

  /// Runs the upload rating image operation.
  Future<String> uploadRatingImage(File imageFile) async {
    return await CloudinaryService.uploadRatingImage(imageFile);
  }

  /// Loads data for the get user profile operation.
  Future<DocumentSnapshot> getUserProfile(String userId) async {
    return await _firestore.collection('users').doc(userId).get();
  }
}
