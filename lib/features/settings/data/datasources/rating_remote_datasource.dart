import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/cloudinary_service.dart';

class RatingRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  RatingRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<DocumentSnapshot> getUserRating(String userId) async {
    return await _firestore.collection('ratings').doc(userId).get();
  }

  Future<QuerySnapshot> getAllRatings() async {
    return await _firestore.collection('ratings').get();
  }

  Future<void> saveRating(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('ratings').doc(userId).set(data);
  }

  Future<void> deleteRating(String userId) async {
    await _firestore.collection('ratings').doc(userId).delete();
  }

  Future<String> uploadRatingImage(File imageFile) async {
    return await CloudinaryService.uploadRatingImage(imageFile);
  }

  Future<DocumentSnapshot> getUserProfile(String userId) async {
    return await _firestore.collection('users').doc(userId).get();
  }
}