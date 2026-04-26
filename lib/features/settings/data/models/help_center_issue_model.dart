import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/help_center_issue.dart';

class HelpCenterIssueModel extends HelpCenterIssue {
  const HelpCenterIssueModel({
    required super.id,
    required super.uid,
    required super.message,
    super.imageUrl,
    required super.replied,
    required super.timestamp,
  });

  factory HelpCenterIssueModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HelpCenterIssueModel(
      id: doc.id,
      uid: data['uid'] as String? ?? '',
      message: data['message'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      replied: data['replied'] as bool? ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'message': message,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'replied': replied,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}