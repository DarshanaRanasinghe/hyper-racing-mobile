import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String username;
  final String email;
  final String? photoUrl;
  final bool online;
  final Timestamp? lastSeen;

  AppUser({
    required this.uid,
    required this.username,
    required this.email,
    this.photoUrl,
    required this.online,
    required this.lastSeen,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      username: (data['username'] ?? 'User').toString(),
      email: (data['email'] ?? '').toString(),
      photoUrl: data['photoUrl']?.toString(),
      online: (data['online'] as bool?) ?? false,
      lastSeen: data['lastSeen'] as Timestamp?,
    );
  }
}
