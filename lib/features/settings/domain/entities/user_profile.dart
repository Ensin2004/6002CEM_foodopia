/// User profile entity
class UserProfile {
  final String uid;
  final String email;
  final String name;
  final String gender;
  final String? profileImageUrl;
  final DateTime? updatedAt;

  UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.gender,
    this.profileImageUrl,
    this.updatedAt,
  });

  // Copy with method for updates
  UserProfile copyWith({
    String? uid,
    String? email,
    String? name,
    String? gender,
    String? profileImageUrl,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}