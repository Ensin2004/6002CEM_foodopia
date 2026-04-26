import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfileModel {
  final String? profileImageUrl;
  final DateTime? lastLogin;

  UserProfileModel({
    this.profileImageUrl,
    this.lastLogin,
  });

  factory UserProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return UserProfileModel(
      profileImageUrl: data?['profileImage'] as String?,
      lastLogin: data?['lastLogin'] != null
          ? (data?['lastLogin'] as Timestamp).toDate()
          : null,
    );
  }
}