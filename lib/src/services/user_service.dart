import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  Future<void> createUserProfile({
    required String uid,
    required String username,
    required String email,
  }) async {
    await _db.collection('users').doc(uid).set({
      'username': username.trim(),
      'email': email.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }
}
