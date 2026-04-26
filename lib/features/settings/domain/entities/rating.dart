/// Rating entity for user ratings and comments
class RatingEntity {
  final String userId;
  final int stars;
  final String comment;
  final String? imageUrl;
  final DateTime updatedAt;

  const RatingEntity({
    required this.userId,
    required this.stars,
    required this.comment,
    this.imageUrl,
    required this.updatedAt,
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasComment => comment.trim().isNotEmpty;
}