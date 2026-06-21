// Handles remote data access for profile.

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/cloudinary_service.dart';

/// Defines behavior for profile remote data source.
/// Handles user profile CRUD operations with Firestore and Firebase Auth.
class ProfileRemoteDataSource {
  /// Firestore instance for database operations.
  final FirebaseFirestore _firestore;

  /// FirebaseAuth instance for authentication operations.
  final FirebaseAuth _auth;

  /// Creates a profile remote data source instance.
  ProfileRemoteDataSource({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Loads data for the get user profile operation.
  Future<DocumentSnapshot> getUserProfile(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  /// Runs the update user name operation.
  Future<void> updateUserName(String uid, String name) async {
    // Split the full name into first and last name parts.
    final nameParts = name.trim().split(RegExp(r'\s+'));
    final firstName = nameParts.isNotEmpty ? nameParts.first : name.trim();
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    // Update user document in Firestore.
    await _firestore.collection('users').doc(uid).update({
      'firstName': firstName,
      'lastName': lastName,
      'name': name,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update display name in Firebase Auth.
    await _auth.currentUser?.updateDisplayName(name);
  }

  /// Runs the update user gender operation.
  Future<void> updateUserGender(String uid, String gender) async {
    await _firestore.collection('users').doc(uid).update({
      'gender': gender,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Runs the upload profile image operation.
  Future<String> uploadProfileImage(File imageFile) async {
    return await CloudinaryService.uploadUserProfileImage(imageFile);
  }

  /// Runs the update profile image operation.
  Future<void> updateProfileImage(String uid, String imageUrl) async {
    // Update user document in Firestore.
    await _firestore.collection('users').doc(uid).update({
      'profileImage': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Update photo URL in Firebase Auth.
    await _auth.currentUser?.updatePhotoURL(imageUrl);
  }
}