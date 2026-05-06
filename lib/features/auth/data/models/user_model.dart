import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/auth/role_manager.dart';
import '../../domain/entities/user_entity.dart';

/// Defines behavior for user model.
class UserModel extends UserEntity {
  /// Creates a user model instance.
  UserModel({
    required super.uid,
    required super.email,
    super.name,
    super.gender,
    super.ageGroupId,
    super.ageGroupName,
    super.role,
    required super.isEmailVerified,
    super.createdAt,
    super.lastLogin,
  });

  /// Creates a user model instance.
  factory UserModel.fromFirebase(User user, DocumentSnapshot? userDoc) {
    final roleManager = RoleManager();

    final data = userDoc?.data() as Map<String, dynamic>?;
    final name = data?['name'] as String?;
    final gender = data?['gender'] as String?;
    final ageGroupId = data?['ageGroupId'] as String?;
    final ageGroupName = data?['ageGroupName'] as String?;
    final role = data?['role'] as String?;

    // Safely handle createdAt - might not exist
    DateTime? createdAt;
    if (data != null) {
      final createdAtTimestamp = data['createdAt'];
      if (createdAtTimestamp != null && createdAtTimestamp is Timestamp) {
        createdAt = createdAtTimestamp.toDate();
      }
    }

    // Safely handle lastLogin - might not exist
    DateTime? lastLogin;
    if (data != null) {
      final lastLoginTimestamp = data['lastLogin'];
      if (lastLoginTimestamp != null && lastLoginTimestamp is Timestamp) {
        lastLogin = lastLoginTimestamp.toDate();
      }
    }

    /// Handles the user model operation.
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      name: name,
      gender: gender,
      ageGroupId: ageGroupId,
      ageGroupName: ageGroupName,
      role: roleManager.fromString(role ?? roleManager.getDefaultRole()),
      isEmailVerified: user.emailVerified,
      createdAt: createdAt,
      lastLogin: lastLogin,
    );
  }

  /// Converts this instance into to json data.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'gender': gender,
      'ageGroupId': ageGroupId,
      'ageGroupName': ageGroupName,
      'role': role.name,
      'lastLogin': lastLogin,
    };
  }
}
