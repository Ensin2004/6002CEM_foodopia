// Handles remote data access for profile.

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/cloudinary_service.dart';

/// Defines behavior for profile remote data source.
class ProfileRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Creates a profile remote data source instance.
  ProfileRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Loads data for the get user profile operation.
  Future<DocumentSnapshot> getUserProfile(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  /// Runs the update user name operation.
  Future<void> updateUserName(String uid, String name) async {
    await _firestore.collection('users').doc(uid).update({'name': name});
    await _auth.currentUser?.updateDisplayName(name);
  }

  /// Runs the update user gender operation.
  Future<void> updateUserGender(String uid, String gender) async {
    await _firestore.collection('users').doc(uid).update({'gender': gender});
  }

  /// Runs the update user age group operation.
  Future<void> updateUserAgeGroup(
    String uid,
    String ageGroupId,
    String ageGroupName,
  ) async {
    await _firestore.collection('users').doc(uid).update({
      'ageGroupId': ageGroupId,
      'ageGroupName': ageGroupName,
    });
  }

  /// Runs the upload profile image operation.
  Future<String> uploadProfileImage(File imageFile) async {
    return await CloudinaryService.uploadUserProfileImage(imageFile);
  }

  /// Runs the update profile image operation.
  Future<void> updateProfileImage(String uid, String imageUrl) async {
    await _firestore.collection('users').doc(uid).update({'profileImage': imageUrl});
    await _auth.currentUser?.updatePhotoURL(imageUrl);
  }
}
