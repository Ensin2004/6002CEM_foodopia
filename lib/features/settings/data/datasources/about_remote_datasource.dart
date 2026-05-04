import 'package:cloud_firestore/cloud_firestore.dart';

/// Defines behavior for about remote data source.
class AboutRemoteDataSource {
  final FirebaseFirestore _firestore;

  /// Creates a about remote data source instance.
  AboutRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Loads data for the get about content operation.
  Future<DocumentSnapshot> getAboutContent(String documentId) async {
    return await _firestore.collection('support').doc(documentId).get();
  }

  // Changed from update to set (creates if not exists, updates if exists)
  Future<void> saveAboutContent(String documentId, String content) async {
    await _firestore.collection('support').doc(documentId).set({
      'content': content,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); // merge: true allows updates without overwriting
  }
}
