/// Help Center Issue Entity
class HelpCenterIssue {
  final String id;
  final String uid;
  final String message;
  final String? imageUrl;
  final bool replied;
  final DateTime timestamp;
  final String adminReply;
  final DateTime? repliedAt;

  /// Creates a help center issue instance.
  const HelpCenterIssue({
    required this.id,
    required this.uid,
    required this.message,
    this.imageUrl,
    required this.replied,
    required this.timestamp,
    this.adminReply = '',
    this.repliedAt,
  });

  /// Handles the is replied operation.
  bool get isReplied => replied;

  /// Handles the is pending operation.
  bool get isPending => !replied;

  /// Handles the copy with operation.
  HelpCenterIssue copyWith({
    String? id,
    String? uid,
    String? message,
    String? imageUrl,
    bool? replied,
    DateTime? timestamp,
    String? adminReply,
    DateTime? repliedAt,
  }) {
    /// Handles the help center issue operation.
    return HelpCenterIssue(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      message: message ?? this.message,
      imageUrl: imageUrl ?? this.imageUrl,
      replied: replied ?? this.replied,
      timestamp: timestamp ?? this.timestamp,
      adminReply: adminReply ?? this.adminReply,
      repliedAt: repliedAt ?? this.repliedAt,
    );
  }
}
