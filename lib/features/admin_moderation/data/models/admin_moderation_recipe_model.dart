import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/admin_moderation_recipe.dart';

/// Data model for admin moderation recipe summaries.
class AdminModerationRecipeModel extends AdminModerationRecipe {
  /// Creates an admin moderation recipe model.
  const AdminModerationRecipeModel({
    required super.id,
    required super.title,
    required super.creatorUid,
    required super.creatorName,
    required super.imagePath,
    required super.isPublished,
    required super.isFinalized,
    required super.reviewStatus,
    required super.updatedAt,
  });

  /// Builds the model from a recipe document and resolved creator name.
  factory AdminModerationRecipeModel.fromFirestore({
    required QueryDocumentSnapshot<Map<String, dynamic>> doc,
    required String creatorName,
  }) {
    final data = doc.data();
    final media = _stringList(data['media']);
    final creatorUid = _stringValue(data['creatorId']).isNotEmpty
        ? _stringValue(data['creatorId'])
        : _stringValue(data['creatorUid']);

    return AdminModerationRecipeModel(
      id: doc.id,
      title: _stringValue(data['name'], fallback: 'Untitled Recipe'),
      creatorUid: creatorUid,
      creatorName: creatorName.trim().isEmpty ? 'Unknown creator' : creatorName,
      imagePath: media.isNotEmpty ? media.first : 'assets/images/empty_page.png',
      isPublished: _stringValue(data['visibility']) == 'public',
      isFinalized: data['isFinalized'] == true,
      reviewStatus: _reviewStatus(data['moderationStatus']),
      updatedAt:
          _dateTime(data['updatedAt']) ??
          _dateTime(data['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

AdminModerationReviewStatus _reviewStatus(Object? value) {
  final status = _stringValue(value);
  if (status.toLowerCase() == 'reviewed') {
    return AdminModerationReviewStatus.reviewed;
  }
  if (status.toLowerCase() == 'hidden') {
    return AdminModerationReviewStatus.hidden;
  }
  return AdminModerationReviewStatus.pending;
}

String _stringValue(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

List<String> _stringList(Object? value) {
  if (value is Iterable) {
    return value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return const [];
}

DateTime? _dateTime(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}
