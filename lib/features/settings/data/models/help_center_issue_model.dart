// Maps stored data for the help center issue model.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/help_center_issue.dart';

/// Defines behavior for help center issue model.
class HelpCenterIssueModel extends HelpCenterIssue {
  /// Creates a help center issue model instance.
  const HelpCenterIssueModel({
    required super.id,
    required super.uid,
    required super.message,
    super.imageUrl,
    required super.replied,
    required super.timestamp,
    super.adminReply,
    super.repliedAt,
  });

  /// Creates a help center issue model instance.
  factory HelpCenterIssueModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] as String?;
    final replied = status != null
        ? status == 'replied' || status == 'closed'
        : data['replied'] as bool? ?? false;
    final createdAt = data['createdAt'] ?? data['timestamp'];
    final repliedAt = data['repliedAt'];

    /// Handles the help center issue model operation.
    return HelpCenterIssueModel(
      id: doc.id,
      uid: data['uid'] as String? ?? '',
      message: data['message'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      replied: replied,
      timestamp: (createdAt as Timestamp?)?.toDate() ?? DateTime.now(),
      adminReply: data['adminReply'] as String? ?? '',
      repliedAt: (repliedAt as Timestamp?)?.toDate(),
    );
  }

  /// Converts this instance into to json data.
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'message': message,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'status': replied ? 'replied' : 'open',
      'adminReply': adminReply,
      'repliedBy': '',
      'repliedAt': repliedAt == null ? null : Timestamp.fromDate(repliedAt!),
      'createdAt': Timestamp.fromDate(timestamp),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
