/// Sort options for the admin moderation recipe list.
enum AdminModerationSortOption { newest, oldest, alphabetAZ, alphabetZA }

/// Review status options for admin moderation.
enum AdminModerationReviewStatus { pending, reviewed, hidden }

/// Review status filter options for admin moderation.
enum AdminModerationReviewFilter { all, pending, reviewed, hidden }

/// Recipe summary shown in the admin moderation list.
class AdminModerationRecipe {
  /// Recipe document ID.
  final String id;

  /// Recipe title.
  final String title;

  /// Creator user ID.
  final String creatorUid;

  /// Creator display name resolved from users collection.
  final String creatorName;

  /// Main recipe image path.
  final String imagePath;

  /// Whether the recipe is visible to users.
  final bool isPublished;

  /// Whether the recipe has been finalized.
  final bool isFinalized;

  /// Admin moderation review status.
  final AdminModerationReviewStatus reviewStatus;

  /// Last updated timestamp.
  final DateTime updatedAt;

  /// Creates an admin moderation recipe summary.
  const AdminModerationRecipe({
    required this.id,
    required this.title,
    required this.creatorUid,
    required this.creatorName,
    required this.imagePath,
    required this.isPublished,
    required this.isFinalized,
    required this.reviewStatus,
    required this.updatedAt,
  });
}
