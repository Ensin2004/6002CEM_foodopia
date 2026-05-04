// Handles remote data access for rating.

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/cloudinary_service.dart';

/// Defines behavior for rating remote data source.
class RatingRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Creates a rating remote data source instance.
  RatingRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Loads data for the get user rating operation.
  Future<DocumentSnapshot> getUserRating(String userId) async {
    return await _firestore.collection('ratings').doc(userId).get();
  }

  /// Loads data for the get all ratings operation.
  Future<QuerySnapshot> getAllRatings() async {
    return await _firestore.collection('ratings').get();
  }

  /// Runs the save rating operation.
  Future<void> saveRating(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('ratings').doc(userId).set(data);
  }

  /// Runs the delete rating operation.
  Future<void> deleteRating(String userId) async {
    await _firestore.collection('ratings').doc(userId).delete();
  }

  /// Runs the upload rating image operation.
  Future<String> uploadRatingImage(File imageFile) async {
    return await CloudinaryService.uploadRatingImage(imageFile);
  }

  /// Loads data for the get user profile operation.
  Future<DocumentSnapshot> getUserProfile(String userId) async {
    return await _firestore.collection('users').doc(userId).get();
  }
}
