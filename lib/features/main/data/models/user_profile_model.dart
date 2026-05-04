// Maps stored data for the user profile model.

import 'package:cloud_firestore/cloud_firestore.dart';

/// Stores profile fields required by the main feature.
class UserProfileModel {
  final String? profileImageUrl;
  final DateTime? lastLogin;

  /// Creates a profile model with optional image and login data.
  UserProfileModel({
    this.profileImageUrl,
    this.lastLogin,
  });

  /// Converts a Firestore user document into a profile model.
  factory UserProfileModel.fromFirestore(DocumentSnapshot doc) {
    // Reads the raw document payload as a nullable map.
    final data = doc.data() as Map<String, dynamic>?;

    // Safely maps missing profile image and login fields to null.
    return UserProfileModel(
      profileImageUrl: data?['profileImage'] as String?,
      lastLogin: data?['lastLogin'] != null
          ? (data?['lastLogin'] as Timestamp).toDate()
          : null,
    );
  }
}
