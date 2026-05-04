/// Rating entity for user ratings and comments
class RatingEntity {
  final String userId;
  final int stars;
  final String comment;
  final String? imageUrl;
  final DateTime updatedAt;

  /// Creates a rating entity instance.
  const RatingEntity({
    required this.userId,
    required this.stars,
    required this.comment,
    this.imageUrl,
    required this.updatedAt,
  });

  /// Handles the has image operation.
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  /// Handles the has comment operation.
  bool get hasComment => comment.trim().isNotEmpty;
}
