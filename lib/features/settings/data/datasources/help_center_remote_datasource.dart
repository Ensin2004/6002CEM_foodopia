// Handles remote data access for help center.

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/cloudinary_service.dart';

/// Defines behavior for help center remote data source.
class HelpCenterRemoteDataSource {
  final FirebaseFirestore _firestore;

  /// Creates a help center remote data source instance.
  HelpCenterRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore
      .collection('support_center')
      .doc('help_tickets')
      .collection('items');

  /// Loads data for the get user issues operation.
  Future<QuerySnapshot> getUserIssues(String uid) async {
    return await _collection
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .get();
  }

  /// Loads data for the get all issues operation.
  Future<QuerySnapshot> getAllIssues() async {
    return await _collection.orderBy('createdAt', descending: true).get();
  }

  /// Handles the add issue operation.
  Future<void> addIssue(Map<String, dynamic> issueData) async {
    await _collection.add(issueData);
  }

  /// Runs the update issue status operation.
  Future<void> updateIssueStatus(String issueId, bool replied) async {
    await _collection.doc(issueId).update({
      'status': replied ? 'replied' : 'open',
      'repliedAt': replied ? FieldValue.serverTimestamp() : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Runs the upload issue image operation.
  Future<String> uploadIssueImage(File imageFile) async {
    return await CloudinaryService.uploadSupportImage(imageFile);
  }

  /// Loads data for the get user data operation.
  Future<DocumentSnapshot> getUserData(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }
}
