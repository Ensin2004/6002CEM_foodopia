import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/cloudinary_service.dart';

class HelpCenterRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  HelpCenterRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<QuerySnapshot> getUserIssues(String uid) async {
    return await _firestore
        .collection('help_center')
        .where('uid', isEqualTo: uid)
        .orderBy('timestamp', descending: true)
        .get();
  }

  Future<QuerySnapshot> getAllIssues() async {
    return await _firestore
        .collection('help_center')
        .orderBy('timestamp', descending: true)
        .get();
  }

  Future<void> addIssue(Map<String, dynamic> issueData) async {
    await _firestore.collection('help_center').add(issueData);
  }

  Future<void> updateIssueStatus(String issueId, bool replied) async {
    await _firestore.collection('help_center').doc(issueId).update({
      'replied': replied,
    });
  }

  Future<String> uploadIssueImage(File imageFile) async {
    return await CloudinaryService.uploadSupportImage(imageFile);
  }

  Future<DocumentSnapshot> getUserData(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }
}