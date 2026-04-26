import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/rating.dart';

class RatingModel extends RatingEntity {
  const RatingModel({
    required super.userId,
    required super.stars,
    required super.comment,
    super.imageUrl,
    required super.updatedAt,
  });

  factory RatingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RatingModel(
      userId: doc.id,
      stars: data['stars'] as int? ?? 0,
      comment: data['comment'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stars': stars,
      'comment': comment,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}