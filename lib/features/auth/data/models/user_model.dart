import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/utils/role_manager.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.uid,
    required super.email,
    super.name,
    super.gender,
    super.countryId,
    super.role,
    required super.isEmailVerified,
    super.createdAt,
    super.lastLogin,
  });

  factory UserModel.fromFirebase(User user, DocumentSnapshot? userDoc) {
    final roleManager = RoleManager();

    // Safely get values with null handling
    final name = userDoc != null ? userDoc.get('name') : null;
    final gender = userDoc != null ? userDoc.get('gender') : null;
    final countryId = userDoc != null ? userDoc.get('countryCurrencyId') : null;
    final role = userDoc != null
        ? userDoc.get('role') as String?
        : null;

    // ✅ Safely handle createdAt - might not exist
    DateTime? createdAt;
    if (userDoc != null && userDoc.data() != null) {
      final createdAtTimestamp = userDoc.get('createdAt');
      if (createdAtTimestamp != null && createdAtTimestamp is Timestamp) {
        createdAt = createdAtTimestamp.toDate();
      }
    }

    // ✅ Safely handle lastLogin - might not exist
    DateTime? lastLogin;
    if (userDoc != null && userDoc.data() != null) {
      final lastLoginTimestamp = userDoc.get('lastLogin');
      if (lastLoginTimestamp != null && lastLoginTimestamp is Timestamp) {
        lastLogin = lastLoginTimestamp.toDate();
      }
    }

    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      name: name,
      gender: gender,
      countryId: countryId,
      role: roleManager.fromString(role ?? roleManager.getDefaultRole()),
      isEmailVerified: user.emailVerified,
      createdAt: createdAt,
      lastLogin: lastLogin,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'gender': gender,
      'countryCurrencyId': countryId,
      'role': role.name,
      'lastLogin': lastLogin,
    };
  }
}