/// Help Center Issue Entity
class HelpCenterIssue {
  final String id;
  final String uid;
  final String message;
  final String? imageUrl;
  final bool replied;
  final String status;
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
    this.status = 'open',
    required this.timestamp,
    this.adminReply = '',
    this.repliedAt,
  });

  /// Handles the is replied operation.
  bool get isReplied => replied;

  /// Handles the is pending operation.
  bool get isPending => !replied;

  /// Handles the normalized status operation.
  String get normalizedStatus {
    final normalized = status.toLowerCase().trim();
    if (normalized == 'closed' || normalized == 'replied') return 'closed';
    return 'open';
  }

  /// Handles the copy with operation.
  HelpCenterIssue copyWith({
    String? id,
    String? uid,
    String? message,
    String? imageUrl,
    bool? replied,
    String? status,
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
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      adminReply: adminReply ?? this.adminReply,
      repliedAt: repliedAt ?? this.repliedAt,
    );
  }
}
