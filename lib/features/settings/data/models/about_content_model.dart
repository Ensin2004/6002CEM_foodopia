import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/about_content.dart';

class AboutContentModel extends AboutContent {
  const AboutContentModel({
    required super.id,
    required super.title,
    required super.content,
    super.updatedAt,
  });

  factory AboutContentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AboutContentModel(
      id: doc.id,
      title: _getTitleFromId(doc.id),
      content: data['content'] ?? '',
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

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

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}