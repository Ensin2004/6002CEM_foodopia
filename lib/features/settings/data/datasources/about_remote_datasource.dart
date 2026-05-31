import 'package:cloud_firestore/cloud_firestore.dart';

/// Defines behavior for about remote data source.
class AboutRemoteDataSource {
  final FirebaseFirestore _firestore;

  /// Creates a about remote data source instance.
  AboutRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Loads data for the get about content operation.
  Future<DocumentSnapshot> getAboutContent(String documentId) async {
    return await _firestore.collection('support_center').doc(documentId).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchAboutContent(
    String documentId,
  ) {
    return _firestore.collection('support_center').doc(documentId).snapshots();
  }

  // Changed from update to set (creates if not exists, updates if exists)
  Future<void> saveAboutContent(String documentId, String content) async {
    await _firestore.collection('support_center').doc(documentId).set(
      {
        'title': _getTitleFromId(documentId),
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    ); // merge: true allows updates without overwriting
  }

  Future<void> deleteAboutContent(String documentId) async {
    await _firestore.collection('support_center').doc(documentId).delete();
  }

  String _getTitleFromId(String id) {
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
}
