// Handles remote data access for rating.

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/cloudinary_service.dart';

/// Defines behavior for rating remote data source.
class RatingRemoteDataSource {
  final FirebaseFirestore _firestore;

  /// Creates a rating remote data source instance.
  RatingRemoteDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection => _firestore
      .collection('support_center')
      .doc('app_rating_feedback')
      .collection('items');

  /// Loads data for the get user rating operation.
  Future<DocumentSnapshot> getUserRating(String userId) async {
    return await _collection.doc(userId).get();
  }

  /// Loads data for the get all ratings operation.
  Future<QuerySnapshot> getAllRatings() async {
    return await _collection.get();
  }

  /// Runs the save rating operation.
  Future<void> saveRating(String userId, Map<String, dynamic> data) async {
    final doc = _collection.doc(userId);
    final existing = await doc.get();
    final writeData = Map<String, dynamic>.from(data);
    if (existing.exists) {
      writeData.remove('createdAt');
    }
    await doc.set(writeData, SetOptions(merge: true));
  }

  /// Runs the delete rating operation.
  Future<void> deleteRating(String userId) async {
    await _collection.doc(userId).delete();
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
