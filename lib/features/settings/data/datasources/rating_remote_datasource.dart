// Handles remote data access for rating.

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/services/fcm_sender.dart';

/// Defines behavior for rating remote data source.
/// Handles CRUD operations for app rating feedback and admin notifications.
class RatingRemoteDataSource {
  /// Firestore instance used for database operations.
  final FirebaseFirestore _firestore;

  /// Creates a rating remote data source instance.
  RatingRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Reference to the app rating feedback subcollection.
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
    // Get reference to the user's rating document.
    final doc = _collection.doc(userId);

    // Check if the document already exists.
    final existing = await doc.get();

    // Prepare data for writing.
    final writeData = Map<String, dynamic>.from(data);

    // Remove createdAt if updating an existing document.
    if (existing.exists) {
      writeData.remove('createdAt');
    }

    // Save the rating.
    await doc.set(writeData, SetOptions(merge: true));

    // Notify admins of the new rating.
    await _notifyAdminsSystemRating(userId: userId, data: writeData);
  }

  /// Notifies all admins of a new system rating.
  Future<void> _notifyAdminsSystemRating({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Get user name and rating details.
      final userName = data['userName']?.toString().trim() ?? '';
      final stars = data['stars']?.toString() ?? '';
      final name = userName.isEmpty ? 'Someone' : userName;

      // Build notification message.
      final message = stars.isEmpty
          ? '$name submitted a new system rating.'
          : '$name submitted a new $stars star system rating.';

      // Get all admin users.
      final admins = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      // Send notification to each admin.
      for (final admin in admins.docs) {
        final adminUid = admin.id;

        // Skip if the admin is the same as the user.
        if (adminUid.isEmpty || adminUid == userId) continue;

        // Create notification document.
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

        // Check if notification preference is enabled.
        if (!await _isAdminNotificationEnabled(
          adminUid: adminUid,
          preferenceId: 'system_rating_notification',
        )) {
          continue;
        }

        // Send push notification.
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

      // Extract and validate tokens.
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