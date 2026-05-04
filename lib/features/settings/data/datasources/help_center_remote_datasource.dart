// Handles remote data access for help center.

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/cloudinary_service.dart';

/// Defines behavior for help center remote data source.
class HelpCenterRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Creates a help center remote data source instance.
  HelpCenterRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Loads data for the get user issues operation.
  Future<QuerySnapshot> getUserIssues(String uid) async {
    return await _firestore
        .collection('help_center')
        .where('uid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .get();
  }

  /// Loads data for the get all issues operation.
  Future<QuerySnapshot> getAllIssues() async {
    return await _firestore
        .collection('help_center')
        .orderBy('timestamp', descending: true)
        .get();
  }

  /// Handles the add issue operation.
  Future<void> addIssue(Map<String, dynamic> issueData) async {
    await _firestore.collection('help_center').add(issueData);
  }

  /// Runs the update issue status operation.
  Future<void> updateIssueStatus(String issueId, bool replied) async {
    await _firestore.collection('help_center').doc(issueId).update({
      'replied': replied,
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
