class AppUser {
  final String uid;
  final String username;
  final String email;
  final String? photoUrl;

  AppUser({
    required this.uid,
    required this.username,
    required this.email,
    this.photoUrl,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      username: (data['username'] ?? 'User').toString(),
      email: (data['email'] ?? '').toString(),
      photoUrl: data['photoUrl']?.toString(),
    );
  }
}
