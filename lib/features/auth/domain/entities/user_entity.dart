import '../../../../core/auth/role_manager.dart';

/// Defines behavior for user entity.
/// Represents a user in the application domain.
class UserEntity {
  /// Unique identifier of the user.
  final String uid;

  /// Email address of the user.
  final String email;

  /// Full name of the user.
  final String? name;

  /// Gender of the user.
  final String? gender;

  /// ID of the user's age group.
  final String? ageGroupId;

  /// Name of the user's age group.
  final String? ageGroupName;

  /// Role of the user (admin or user).
  final AppRole role;

  /// Whether the user's email is verified.
  final bool isEmailVerified;

  /// Timestamp when the user account was created.
  final DateTime? createdAt;

  /// Timestamp of the user's last login.
  final DateTime? lastLogin;

  /// Creates a user entity instance.
  UserEntity({
    required this.uid,
    required this.email,
    this.name,
    this.gender,
    this.ageGroupId,
    this.ageGroupName,
    this.role = AppRole.user,  // Default to user.
    required this.isEmailVerified,
    this.createdAt,
    this.lastLogin,
  });

  // =========================================================================
  // HELPER GETTERS
  // =========================================================================

  /// Whether the user is an admin.
  bool get isAdmin => role == AppRole.admin;

  /// Whether the user is a regular user.
  bool get isUser => role == AppRole.user;

  // =========================================================================
  // SERIALIZATION
  // =========================================================================

  /// Convert to JSON for Firebase.
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'gender': gender,
      'ageGroupId': ageGroupId,
      'ageGroupName': ageGroupName,
      'role': role.name,  // Store as string in Firebase.
      'isEmailVerified': isEmailVerified,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
    };
  }

  /// Create from JSON from Firebase.
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