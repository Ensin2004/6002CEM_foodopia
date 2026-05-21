// Maps stored data for the rating model.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/rating.dart';

/// Defines behavior for rating model.
class RatingModel extends RatingEntity {
  /// Creates a rating model instance.
  const RatingModel({
    required super.userId,
    required super.stars,
    required super.comment,
    super.imageUrl,
    required super.updatedAt,
  });

  /// Creates a rating model instance.
  factory RatingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    /// Handles the rating model operation.
    return RatingModel(
      userId: doc.id,
      stars: data['stars'] as int? ?? 0,
      comment: data['comment'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converts this instance into to json data.
  Map<String, dynamic> toJson() {
    return {
      'uid': userId,
      'stars': stars,
      'comment': comment,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'status': 'new',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
