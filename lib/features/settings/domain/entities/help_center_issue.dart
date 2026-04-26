import 'package:cloud_firestore/cloud_firestore.dart';

/// Help Center Issue Entity
class HelpCenterIssue {
  final String id;
  final String uid;
  final String message;
  final String? imageUrl;
  final bool replied;
  final DateTime timestamp;

  const HelpCenterIssue({
    required this.id,
    required this.uid,
    required this.message,
    this.imageUrl,
    required this.replied,
    required this.timestamp,
  });

  bool get isReplied => replied;
  bool get isPending => !replied;

  HelpCenterIssue copyWith({
    String? id,
    String? uid,
    String? message,
    String? imageUrl,
    bool? replied,
    DateTime? timestamp,
  }) {
    return HelpCenterIssue(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      replied: replied ?? this.replied,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}