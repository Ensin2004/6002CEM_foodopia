class LibraryProfile {
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

class LibraryProfileUser {
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
