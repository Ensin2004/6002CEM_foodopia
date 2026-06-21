part of 'explore_remote_datasource.dart';

/// Extension handling community-related data retrieval for the ExploreRemoteDataSource.
///
/// Contains methods for fetching and constructing community data structures
/// including ratings breakdowns, reviews, comments, and nested reply threads.
/// All community data is retrieved from Firestore subcollections and assembled
/// into domain entities.
extension ExploreRemoteDataSourceCommunity on ExploreRemoteDataSource {
  /// Retrieves and constructs the complete community data for a recipe.
  ///
  /// Fetches all ratings and comments from the recipe's subcollections,
  /// calculates the rating breakdown distribution, and builds the full
  /// [ExploreCommunity] object including author bio, ratings breakdown,
  /// reviews, and comments.
  Future<ExploreCommunity> _getCommunity(
      DocumentReference<Map<String, dynamic>> recipe,
      String fallbackAuthor,
      ) async {
    // Fetch all ratings sorted by creation date (newest first).
    final ratingsSnapshot = await recipe
        .collection('ratings')
        .orderBy('createdAt', descending: true)
        .get();
    // Fetch all comments sorted by creation date (newest first).
    final commentsSnapshot = await recipe
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .get();
    final ratings = <ExploreReview>[];
    // Initialize the breakdown map with zero counts for each star rating (1-5).
    final breakdown = {for (var star = 1; star <= 5; star++) star: 0};

    // Process each rating document to build review objects and breakdown counts.
    for (final doc in ratingsSnapshot.docs) {
      final data = doc.data();
      final rating = _doubleValue(data['rating']);
      // Round the rating to the nearest integer and clamp to valid range (1-5).
      final roundedRating = rating.round().clamp(1, 5);
      // Increment the count for the corresponding star rating.
      breakdown[roundedRating] = (breakdown[roundedRating] ?? 0) + 1;
      // Retrieve the creator information for the rating's author.
      final creator = await _getCreator(_stringValue(data['userId']));
      final createdAt = _dateTime(data['createdAt']);
      ratings.add(
        ExploreReview(
          author: creator.name,
          avatarPath: creator.profileImage,
          timeAgo: _dateLabel(createdAt),
          createdAt: createdAt,
          rating: rating,
        ),
      );
    }

    // Process each comment document to build comment objects.
    final comments = <ExploreComment>[];
    for (final doc in commentsSnapshot.docs) {
      comments.add(await _commentFromDoc(doc));
    }

    // Assemble and return the complete community data structure.
    return ExploreCommunity(
      authorBio: 'Recipe shared by $fallbackAuthor.',
      ratingBreakdown: List.generate(5, (index) {
        final stars = 5 - index;
        return ExploreRatingBreakdown(
          stars: stars,
          count: breakdown[stars] ?? 0,
        );
      }),
      reviews: ratings,
      comments: comments,
    );
  }

  /// Constructs an [ExploreComment] object from a Firestore comment document.
  ///
  /// Retrieves the comment author, determines if the current user has liked
  /// the comment, fetches all replies, and recursively processes nested replies.
  Future<ExploreComment> _commentFromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) async {
    final data = doc.data();
    // Fetch the creator information for the comment author.
    final creator = await _getCreator(_stringValue(data['userId']));
    final createdAt = _dateTime(data['createdAt']);
    final uid = auth.currentUser?.uid ?? '';
    // Check if the current user has liked this comment.
    final isLiked = uid.isNotEmpty
        ? (await doc.reference.collection('likedBy').doc(uid).get()).exists
        : false;
    // Fetch all replies for this comment, sorted by creation date (oldest first).
    final repliesSnapshot = await doc.reference
        .collection('replies')
        .orderBy('createdAt', descending: false)
        .get();
    final replies = <ExploreCommentReply>[];
    // Recursively process each reply document.
    for (final replyDoc in repliesSnapshot.docs) {
      replies.add(await _replyFromDoc(replyDoc));
    }

    // Build and return the complete comment object.
    return ExploreComment(
      id: doc.id,
      author: creator.name,
      avatarPath: creator.profileImage,
      timeAgo: _dateLabel(createdAt),
      createdAt: createdAt,
      content: _stringValue(data['content']),
      likes: _intValue(data['likes']),
      isLiked: isLiked,
      replies: replies,
    );
  }

  /// Constructs an [ExploreCommentReply] object from a Firestore reply document.
  ///
  /// Retrieves the reply author, determines if the current user has liked
  /// the reply, and recursively fetches any nested replies (replies to replies).
  Future<ExploreCommentReply> _replyFromDoc(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
      ) async {
    final data = doc.data();
    // Fetch the creator information for the reply author.
    final creator = await _getCreator(_stringValue(data['userId']));
    final createdAt = _dateTime(data['createdAt']);
    final uid = auth.currentUser?.uid ?? '';
    // Check if the current user has liked this reply.
    final isLiked = uid.isNotEmpty
        ? (await doc.reference.collection('likedBy').doc(uid).get()).exists
        : false;
    // Recursively fetch any nested replies (replies to this reply).
    final nestedSnapshot = await doc.reference
        .collection('replies')
        .orderBy('createdAt', descending: false)
        .get();
    final replies = <ExploreCommentReply>[];
    for (final nestedDoc in nestedSnapshot.docs) {
      replies.add(await _replyFromDoc(nestedDoc));
    }
    // Build and return the complete reply object with its document path.
    return ExploreCommentReply(
      id: doc.id,
      documentPath: doc.reference.path,
      author: creator.name,
      avatarPath: creator.profileImage,
      timeAgo: _dateLabel(createdAt),
      createdAt: createdAt,
      content: _stringValue(data['content']),
      likes: _intValue(data['likes']),
      isLiked: isLiked,
      replies: replies,
    );
  }
}