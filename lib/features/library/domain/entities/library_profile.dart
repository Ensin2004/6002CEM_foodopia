// Represents a user's library profile, contains user personal information
class LibraryProfile {
  // The user's display name, biography, profile picture, followers and following
  final String name;
  final String bio;
  final String imageUrl;
  final int followersCount;
  final int followingCount;

  const LibraryProfile({
    required this.name,
    required this.bio,
    required this.imageUrl,
    required this.followersCount,
    required this.followingCount,
  });
}

// Represents a simplified user profile for displaying in lists.
class LibraryProfileUser {
  // The user's uid, display name, profile picture, number of followers
  final String uid;
  final String name;
  final String imageUrl;
  final int followerCount;

  const LibraryProfileUser({
    required this.uid,
    required this.name,
    required this.imageUrl,
    required this.followerCount,
  });
}
