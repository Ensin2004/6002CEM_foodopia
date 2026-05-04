// Handles remote data access for main.

import 'package:cloud_firestore/cloud_firestore.dart';

/// Defines behavior for main remote data source.
class MainRemoteDataSource {
  final FirebaseFirestore _firestore;

  /// Creates a data source backed by Firestore.
  MainRemoteDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Reads a single user document from the users collection.
  Future<DocumentSnapshot> getUserData(String userId) async {
    // Selects the document matching the provided user id.
    return await _firestore.collection('users').doc(userId).get();
  }

  /// Updates selected fields on a user document.
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    // Applies only the supplied fields to the existing document.
    await _firestore.collection('users').doc(userId).update(data);
  }
}
