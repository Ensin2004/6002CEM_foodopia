// Maps stored data for the user profile model.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_profile.dart';

/// Defines behavior for user profile model.
class UserProfileModel extends UserProfile {
  /// Creates a user profile model instance.
  UserProfileModel({
    required super.uid,
    required super.email,
    required super.name,
    required super.gender,
    required super.ageGroupId,
    required super.ageGroupName,
    super.profileImageUrl,
    super.updatedAt,
  });

  /// Creates a user profile model instance.
  factory UserProfileModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    /// Handles the user profile model operation.
    return UserProfileModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      gender: data['gender'] ?? '',
      ageGroupId: data['ageGroupId'] ?? '',
      ageGroupName: data['ageGroupName'] ?? '',
      profileImageUrl: data['profileImage'],
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Converts this instance into to json data.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'gender': gender,
      'ageGroupId': ageGroupId,
      'ageGroupName': ageGroupName,
      if (profileImageUrl != null) 'profileImage': profileImageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
