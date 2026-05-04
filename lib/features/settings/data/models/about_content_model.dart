// Maps stored data for the about content model.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/about_content.dart';

/// Defines behavior for about content model.
class AboutContentModel extends AboutContent {
  /// Creates a about content model instance.
  const AboutContentModel({
    required super.id,
    required super.title,
    required super.content,
    super.updatedAt,
  });

  /// Creates a about content model instance.
  factory AboutContentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    /// Handles the about content model operation.
    return AboutContentModel(
      id: doc.id,
      title: _getTitleFromId(doc.id),
      content: data['content'] ?? '',
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Handles the get title from id operation.
  static String _getTitleFromId(String id) {
    switch (id) {
      case 'about_us':
        return 'About Us';
      case 'terms_and_conditions':
        return 'Terms & Conditions';
      case 'privacy_policy':
        return 'Privacy Policy';
      default:
        return id;
    }
  }

  /// Converts this instance into to json data.
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
