import 'package:cloud_firestore/cloud_firestore.dart';

class AboutRemoteDataSource {
  final FirebaseFirestore _firestore;

  AboutRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<DocumentSnapshot> getAboutContent(String documentId) async {
    return await _firestore.collection('support').doc(documentId).get();
  }

  // ✅ Changed from update to set (creates if not exists, updates if exists)
  Future<void> saveAboutContent(String documentId, String content) async {
    await _firestore.collection('support').doc(documentId).set({
      'content': content,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)); // merge: true allows updates without overwriting
  }
}