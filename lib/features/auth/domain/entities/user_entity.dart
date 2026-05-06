
import '../../../../core/auth/role_manager.dart';

/// Defines behavior for user entity.
class UserEntity {
  final String uid;
  final String email;
  final String? name;
  final String? gender;
  final String? ageGroupId;
  final String? ageGroupName;
  final AppRole role;
  final bool isEmailVerified;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  /// Creates a user entity instance.
  UserEntity({
    required this.uid,
    required this.email,
    this.name,
    this.gender,
    this.ageGroupId,
    this.ageGroupName,
    this.role = AppRole.user,  // Default to user
    required this.isEmailVerified,
    this.createdAt,
    this.lastLogin,
  });

  // Helper getters
  bool get isAdmin => role == AppRole.admin;
  /// Handles the is user operation.
  bool get isUser => role == AppRole.user;

  // Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'gender': gender,
      'ageGroupId': ageGroupId,
      'ageGroupName': ageGroupName,
      'role': role.name,  // Store as string in Firebase
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
    };
  }

  // Create from JSON from Firebase
  factory UserEntity.fromJson(Map<String, dynamic> json) {
    /// Handles the user entity operation.
    return UserEntity(
      uid: json['uid'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      gender: json['gender'] as String?,
      ageGroupId: json['ageGroupId'] as String?,
      ageGroupName: json['ageGroupName'] as String?,
      role: RoleManager().fromString(json['role'] as String?),
      isEmailVerified: json['isEmailVerified'] as bool,
      createdAt: json['createdAt']?.toDate(),
      lastLogin: json['lastLogin']?.toDate(),
    );
  }
}
