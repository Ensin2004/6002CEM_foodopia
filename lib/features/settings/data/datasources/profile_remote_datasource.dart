import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/cloudinary_service.dart';

class ProfileRemoteDataSource {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ProfileRemoteDataSource({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<DocumentSnapshot> getUserProfile(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  Future<void> updateUserName(String uid, String name) async {
    await _firestore.collection('users').doc(uid).update({'name': name});
    await _auth.currentUser?.updateDisplayName(name);
  }

  Future<void> updateUserGender(String uid, String gender) async {
    await _firestore.collection('users').doc(uid).update({'gender': gender});
  }

  Future<String> uploadProfileImage(File imageFile) async {
    return await CloudinaryService.uploadUserProfileImage(imageFile);
  }

  Future<void> updateProfileImage(String uid, String imageUrl) async {
    await _firestore.collection('users').doc(uid).update({'profileImage': imageUrl});
    await _auth.currentUser?.updatePhotoURL(imageUrl);
  }
}