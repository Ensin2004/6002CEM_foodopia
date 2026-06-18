// Handles remote data access for help center.

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/cloudinary_service.dart';
import '../../../../core/services/fcm_sender.dart';

/// Defines behavior for help center remote data source.
/// Handles CRUD operations for help tickets and admin notifications.
class HelpCenterRemoteDataSource {
  /// Firestore instance used for database operations.
  final FirebaseFirestore _firestore;

  /// Creates a help center remote data source instance.
  HelpCenterRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Reference to the help tickets subcollection.
  CollectionReference<Map<String, dynamic>> get _collection => _firestore
      .collection('support_center')
      .doc('help_tickets')
      .collection('items');

  /// Loads data for the get user issues operation.
  Future<QuerySnapshot> getUserIssues(String uid) async {
    return await _collection.where('uid', isEqualTo: uid).get();
  }

  /// Loads data for the get all issues operation.
  Future<QuerySnapshot> getAllIssues() async {
    return await _collection.orderBy('createdAt', descending: true).get();
  }

  /// Handles the add issue operation.
  Future<void> addIssue(Map<String, dynamic> issueData) async {
    final docRef = await _collection.add(issueData);
    await _notifyAdminsOfNewTicket(docRef.id, issueData);
  }

  /// Runs the update issue status operation.
  Future<void> updateIssueStatus(String issueId, bool replied) async {
    await _collection.doc(issueId).update({
      'status': replied ? 'replied' : 'open',
      'repliedAt': replied ? FieldValue.serverTimestamp() : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Replies to an issue and notifies the user.
  Future<void> replyToIssue({
    required String issueId,
    required String userUid,
    required String reply,
  }) async {
    // Update the issue with the reply.
    await _collection.doc(issueId).update({
      'status': 'replied',
      'adminReply': reply,
      'repliedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Notify the user of the reply.
    await _notifyUserOfReply(userUid: userUid, issueId: issueId, reply: reply);
  }

  /// Runs the upload issue image operation.
  Future<String> uploadIssueImage(File imageFile) async {
    return await CloudinaryService.uploadSupportImage(imageFile);
  }

  /// Loads data for the get user data operation.
  Future<DocumentSnapshot> getUserData(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  /// Retrieves all admin users.
  Future<QuerySnapshot<Map<String, dynamic>>> getAdminUsers() async {
    return await _firestore
        .collection('users')
        .where('role', isEqualTo: 'admin')
        .get();
  }

  /// Notifies all admins of a new help ticket.
  Future<void> _notifyAdminsOfNewTicket(
      String issueId,
      Map<String, dynamic> issueData,
      ) async {
    try {
      // Get all admin users.
      final admins = await getAdminUsers();

      // Get user details for the ticket.
      final userUid = issueData['uid']?.toString() ?? '';
      final userDoc = await getUserData(userUid);
      final user = userDoc.data() as Map<String, dynamic>?;
      final name = user?['name']?.toString().trim();

      // Build notification data.
      final title = 'New Help Ticket';
      final message =
          '${name?.isNotEmpty == true ? name : 'A user'} submitted a help ticket.';

      // Send notification to each admin.
      for (final adminDoc in admins.docs) {
        final adminUid = adminDoc.id;

        // Create notification document.
        final notificationRef = await _firestore
            .collection('users')
            .doc(adminUid)
            .collection('notifications')
            .add({
          'type': 'newHelpTicket',
          'title': title,
          'message': message,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
          'issueId': issueId,
        });

        // Check if notification preference is enabled.
        if (!await _isNotificationEnabled(
          uid: adminUid,
          preferenceId: 'new_help_ticket_notification',
        )) {
          continue;
        }

        // Send push notification.
        await _sendPushToUser(
          uid: adminUid,
          title: title,
          message: message,
          data: {
            'type': 'newHelpTicket',
            'issueId': issueId,
            'notificationId': notificationRef.id,
          },
        );
      }
    } catch (_) {
      // Support ticket creation should not fail because notification failed.
    }
  }

  /// Notifies a user of a reply to their help ticket.
  Future<void> _notifyUserOfReply({
    required String userUid,
    required String issueId,
    required String reply,
  }) async {
    try {
      // Build notification data.
      final title = 'Help Center Reply';
      final message = reply.length > 90
          ? '${reply.substring(0, 90)}...'
          : reply;

      // Create notification document.
      final notificationRef = await _firestore
          .collection('users')
          .doc(userUid)
          .collection('notifications')
          .add({
        'type': 'helpReply',
        'title': title,
        'message': message,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'issueId': issueId,
      });

      // Check if notification preference is enabled.
      if (!await _isNotificationEnabled(
        uid: userUid,
        preferenceId: 'help_center_reply_notification',
      )) {
        return;
      }

      // Send push notification.
      await _sendPushToUser(
        uid: userUid,
        title: title,
        message: message,
        data: {
          'type': 'helpReply',
          'issueId': issueId,
          'notificationId': notificationRef.id,
        },
      );
    } catch (_) {
      // Reply save should remain successful even if push notification fails.
    }
  }

  /// Checks if a notification preference is enabled.
  Future<bool> _isNotificationEnabled({
    required String uid,
    required String preferenceId,
  }) async {
    final preferenceDoc = await _firestore
        .collection('users')
        .doc(uid)
        .collection('notification_preferences')
        .doc(preferenceId)
        .get();

    final enabled = preferenceDoc.data()?['enabled'];
    return enabled is bool ? enabled : true;
  }

  /// Sends a push notification to a user.
  Future<void> _sendPushToUser({
    required String uid,
    required String title,
    required String message,
    required Map<String, dynamic> data,
  }) async {
    // Get the user's FCM tokens.
    final userDoc = await getUserData(uid);
    final rawTokens = (userDoc.data() as Map<String, dynamic>?)?['fcmTokens'];

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
  }
}