class LibrarySocialProfile {
  final String uid;
  final String name;
  final String bio;
  final String imageUrl;
  final int followersCount;
  final int followingCount;

  const LibrarySocialProfile({
    required this.uid,
    required this.name,
    required this.bio,
    required this.imageUrl,
    required this.followersCount,
    required this.followingCount,
  });
}
