/// User profile entity
class UserProfile {
  final String uid;
  final String email;
  final String name;
  final String gender;
  final String ageGroupId;
  final String ageGroupName;
  final String? profileImageUrl;
  final DateTime? updatedAt;

  /// Creates a user profile instance.
  UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.gender,
    required this.ageGroupId,
    required this.ageGroupName,
    this.profileImageUrl,
    this.updatedAt,
  });

  // Copy with method for updates
  UserProfile copyWith({
    String? uid,
    String? email,
    String? name,
    String? gender,
    String? ageGroupId,
    String? ageGroupName,
    String? profileImageUrl,
    DateTime? updatedAt,
  }) {
    /// Handles the user profile operation.
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      ageGroupId: ageGroupId ?? this.ageGroupId,
      ageGroupName: ageGroupName ?? this.ageGroupName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
